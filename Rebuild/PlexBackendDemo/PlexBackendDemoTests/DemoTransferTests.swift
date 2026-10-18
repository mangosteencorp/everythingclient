import Foundation
import Plex_Shared_Backend
@testable import PlexBackendDemo
import Testing

private final class DownloadFixtureProtocol: URLProtocol, @unchecked Sendable {
    override static func canInit(with request: URLRequest) -> Bool { request.url?.host == "transfer.invalid" }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: url.path == "/error" ? 403 : 200,
                  httpVersion: nil,
                  headerFields: ["Content-Length": "7"]
              ) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("fixture".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
struct DemoTransferTests {
    @Test func serialQueuePersistsSuccessAndContinuesPastFailedSidecar() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let transfers = DemoTransfers(directory: directory) {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [DownloadFixtureProtocol.self]
            return configuration
        }
        let goodURL = try #require(URL(string: "https://transfer.invalid/video.mp4"))
        let badURL = try #require(URL(string: "https://transfer.invalid/error"))
        let nextURL = try #require(URL(string: "https://transfer.invalid/second.mp4"))
        transfers.enqueueRequest(URLRequest(url: goodURL), title: "Video", fileExtension: "mp4")
        transfers.enqueueRequest(URLRequest(url: badURL), title: "Subtitle", fileExtension: "srt")
        transfers.enqueueRequest(URLRequest(url: nextURL), title: "Second", fileExtension: "mp4")
        #expect(transfers.downloads.map(\.status) == [.downloading, .queued, .queued])
        transfers.enqueueRequest(URLRequest(url: goodURL), title: "Duplicate", fileExtension: "mp4")
        #expect(transfers.downloads.count == 3)
        for _ in 0..<300
            where transfers.downloads.contains(where: { $0.status == .downloading || $0.status == .queued }) {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(transfers.downloads.map(\.status) == [.completed, .failed, .completed])
        let first = try #require(transfers.downloads.first)
        #expect(try Data(contentsOf: transfers.fileURL(for: first)) == Data("fixture".utf8))
        let reloaded = DemoTransfers(directory: directory)
        #expect(reloaded.downloads.count == 2)
        transfers.removeCompleted(first.id)
        #expect(!FileManager.default.fileExists(atPath: transfers.fileURL(for: first).path))
        #expect(DemoTransfers(directory: directory).downloads.count == 1)
    }

    @Test func plannedDownloadKeepsItsMetadataForTheOfflineLibrary() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let transfers = DemoTransfers(directory: directory) {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [DownloadFixtureProtocol.self]
            return configuration
        }
        let identity = try PlexClientIdentity(identifier: "t", product: "T", version: "1", platform: "iOS")
        let configuration = try PlexServerConfiguration(baseURL: #require(URL(string: "https://transfer.invalid")), token: "t", identity: identity)
        let item = PlexMetadata(ratingKey: "7", title: "Movie", type: "movie", media: [
            PlexMediaVersion(container: "mp4", parts: [PlexMediaPart(key: "/video.mp4", container: "mp4")]),
        ])
        let plan = try PlexDownloadPlanner(configuration: configuration).plan(for: item)
        transfers.enqueue(plan, item: item, serverID: "server", includeSubtitles: true)
        transfers.enqueue(plan, item: item, serverID: "server", includeSubtitles: true)
        #expect(transfers.downloads.count == 1)
        for _ in 0..<300 where transfers.offlineItems.isEmpty { try await Task.sleep(for: .milliseconds(10)) }
        #expect(transfers.offlineItems.first?.item == item && transfers.offlineItems.first?.serverID == "server")
        #expect(DemoTransfers(directory: directory).offlineItems.first?.item?.media.first?.container == "mp4")
        transfers.enqueue(plan, item: item, serverID: "server", includeSubtitles: true)
        #expect(transfers.downloads.count == 1)
    }

    @Test func signOutCancelsQueuedTransfersAndDropsRetryCredentials() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let transfers = DemoTransfers(directory: directory) {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [DownloadFixtureProtocol.self]
            return configuration
        }
        let url = try #require(URL(string: "https://transfer.invalid/video.mp4"))
        transfers.enqueueRequest(URLRequest(url: url), title: "Video", fileExtension: "mp4")
        transfers.cancelActive()
        let item = try #require(transfers.downloads.first)
        #expect(item.status == .cancelled && !transfers.canRestart(item.id))
        try await Task.sleep(for: .milliseconds(50))
        #expect(transfers.downloads.first?.status == .cancelled)
        #expect(!FileManager.default.fileExists(atPath: transfers.fileURL(for: item).path))
    }
}
