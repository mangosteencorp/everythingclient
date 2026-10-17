import Foundation
import Plex_Shared_Backend
@testable import PlexBackendDemo
import Testing

private actor LibraryLoadingTransport: PlexHTTPTransport {
    private let delaysFirstLibrary: Bool
    private var releaseContinuation: CheckedContinuation<Void, Never>?
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private var blocked = false
    private(set) var requests: [URLRequest] = []

    init(delaysFirstLibrary: Bool = false) { self.delaysFirstLibrary = delaysFirstLibrary }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let url = try #require(request.url)
        if delaysFirstLibrary, url.path == "/library/sections/1/all" {
            blocked = true
            startedContinuation?.resume()
            startedContinuation = nil
            await withCheckedContinuation { releaseContinuation = $0 }
        }
        let start = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
            .first { $0.name == "X-Plex-Container-Start" }?.value ?? "0"
        let keys = url.path == "/library/sections/1/all" ? ["old"]
            : start == "0" ? ["new", "duplicate"] : ["duplicate", "last"]
        let body: [String: Any] = ["MediaContainer": [
            "totalSize": 4, "offset": Int(start) ?? 0,
            "Metadata": keys.map { ["ratingKey": $0, "title": $0, "type": "movie"] },
        ]]
        let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        return (try JSONSerialization.data(withJSONObject: body), response)
    }

    func waitUntilBlocked() async {
        if !blocked { await withCheckedContinuation { startedContinuation = $0 } }
    }

    func release() { releaseContinuation?.resume(); releaseContinuation = nil }
}

@MainActor
struct PagedItemsModelTests {
    @Test func latePreviousLibraryCannotReplaceNewSelectionOrPaging() async throws {
        let transport = LibraryLoadingTransport(delaysFirstLibrary: true)
        let api = try service(transport)
        let model = PagedItemsModel(pageSize: 2)
        let oldLoad = Task { await model.load(api: api) { try await $0.items(sectionID: "1", page: $1) } }
        await transport.waitUntilBlocked()
        await model.load(api: api) { try await $0.items(sectionID: "2", page: $1) }
        #expect(model.items.map(\.ratingKey) == ["new", "duplicate"])
        #expect(model.hasLoaded && !model.loading && model.canLoadMore && model.nextOffset == 2)
        await transport.release()
        await oldLoad.value
        #expect(model.items.map(\.ratingKey) == ["new", "duplicate"] && model.total == 4 && model.error == nil)
        await model.loadMore()
        #expect(model.items.map(\.ratingKey) == ["new", "duplicate", "last"])
        #expect(model.nextOffset == 4 && !model.canLoadMore)
        let requests = await transport.requests
        #expect(requests.map { $0.url?.path } == ["/library/sections/1/all", "/library/sections/2/all", "/library/sections/2/all"])
        let lastURL = try #require(requests.last?.url)
        #expect(URLComponents(url: lastURL, resolvingAgainstBaseURL: false)?.queryItems?
            .first { $0.name == "X-Plex-Container-Start" }?.value == "2")
    }

    @Test func failuresAreReportedAndRemovalKeepsOtherEntries() async throws {
        let api = try service(LibraryLoadingTransport())
        let model = PagedItemsModel()
        await model.load(api: api) { _, _ in throw URLError(.notConnectedToInternet) }
        #expect(model.items.isEmpty && model.error != nil && !model.loading)
        await model.load(api: api) { try await $0.items(sectionID: "2", page: $1) }
        model.remove(try #require(model.items.first))
        #expect(model.items.map(\.ratingKey) == ["duplicate"])
    }

    private func service(_ transport: LibraryLoadingTransport) throws -> PlexAPIService {
        let url = try #require(URL(string: "https://library.invalid"))
        let identity = try PlexClientIdentity(identifier: "library-tests", product: "Tests", version: "1", platform: "Tests")
        return try PlexAPIService(configuration: PlexServerConfiguration(baseURL: url, token: "fixture", identity: identity), transport: transport)
    }
}
