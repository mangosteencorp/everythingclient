import Foundation
import Observation
import Plex_Shared_Backend

struct DemoDownload: Identifiable, Codable, Equatable {
    enum Status: String, Codable { case queued, downloading, pausing, paused, completed, failed, cancelled }
    let id: UUID
    let title: String
    let fileName: String
    var status: Status
    var received: Int64 = 0
    var expected: Int64 = 0
    var message: String?
    /// The owning server, so offline watch changes sync back to it.
    var serverID: String?
    /// Metadata snapshot for the video file (nil for subtitle sidecars) — browsable without a connection.
    var item: PlexMetadata?
    var progress: Double? { expected > 0 ? min(Double(received) / Double(expected), 1) : nil }
}

private struct DemoTransferRun {
    let session: URLSession
    let task: URLSessionDownloadTask
    let generation: UUID
}

/// Foreground, serial transfers. Only completed file records survive relaunch.
/// Requests, credentials and resume data are kept in memory.
@MainActor
@Observable
final class DemoTransfers {
    private(set) var downloads: [DemoDownload] = []
    private(set) var storageError: String?
    @ObservationIgnored private var active: [UUID: DemoTransferRun] = [:]
    @ObservationIgnored private var requests: [UUID: URLRequest] = [:]
    @ObservationIgnored private var resumes: [UUID: Data] = [:]
    @ObservationIgnored private var pauses: [UUID: UUID] = [:]
    @ObservationIgnored private let configuration: () -> URLSessionConfiguration
    let directory: URL

    init(directory: URL? = nil, configuration: @escaping () -> URLSessionConfiguration = { .ephemeral }) {
        self.directory = directory ?? URL.applicationSupportDirectory.appending(
            path: "PlexBackendDemo/Downloads",
            directoryHint: .isDirectory
        )
        self.configuration = configuration
        do {
            try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
            let manifest = self.directory.appending(path: "downloads.json")
            if FileManager.default.fileExists(atPath: manifest.path) {
                downloads = try JSONDecoder().decode([DemoDownload].self, from: Data(contentsOf: manifest)).filter {
                    $0.status == .completed && $0.fileName == URL(filePath: $0.fileName).lastPathComponent &&
                        FileManager.default.fileExists(atPath: self.directory.appending(path: $0.fileName).path)
                }
            }
        } catch { storageError = String(localized: "The download folder or saved manifest could not be opened.") }
    }

    /// Queues every planned part (and optionally its external subtitles). Already queued or downloaded files are skipped.
    func enqueue(_ plan: PlexDownloadPlan, item: PlexMetadata, serverID: String, includeSubtitles: Bool) {
        for part in plan.parts {
            let title = plan.parts.count > 1 ? String(localized: "\(item.title) — part \(part.partIndex + 1)") : item.title
            let suffix = part.part.container ?? part.request.url?.pathExtension ?? "mkv"
            add(part.request, title: title, fileExtension: suffix, serverID: serverID, item: item)
            guard includeSubtitles else { continue }
            for subtitle in part.subtitles {
                let name = subtitle.stream.displayTitle ?? subtitle.stream.language ?? subtitle.fileExtension
                add(subtitle.request, title: String(localized: "\(item.title) — \(name)"), fileExtension: subtitle.fileExtension, serverID: serverID)
            }
        }
    }

    func enqueueRequest(_ request: URLRequest, title: String, fileExtension: String) {
        add(request, title: title, fileExtension: fileExtension)
    }

    /// Completed videos that can be played without a connection.
    var offlineItems: [DemoDownload] { downloads.filter { $0.status == .completed && $0.item != nil } }

    private func add(_ request: URLRequest, title: String, fileExtension: String, serverID: String? = nil, item: PlexMetadata? = nil) {
        let unfinished: [DemoDownload.Status] = [.queued, .downloading, .pausing, .paused]
        guard !downloads.contains(where: { requests[$0.id] == request && unfinished.contains($0.status) }),
              !downloads.contains(where: { $0.status == .completed && $0.serverID == serverID && $0.title == title && serverID != nil })
        else { return }
        let id = UUID()
        let suffix = fileExtension.lowercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
        let fileName = id.uuidString + "." + (suffix.isEmpty ? "bin" : String(suffix.prefix(12)))
        downloads.append(DemoDownload(id: id, title: title, fileName: fileName, status: .queued, serverID: serverID, item: item))
        requests[id] = request
        advance()
    }

    func fileURL(for download: DemoDownload) -> URL { directory.appending(path: download.fileName) }
    func canRestart(_ id: UUID) -> Bool { requests[id] != nil }

    func start(_ id: UUID) {
        guard let index = downloads.firstIndex(where: { $0.id == id }), let request = requests[id],
              ![.completed, .pausing, .downloading].contains(downloads[index].status) else { return }
        downloads[index].status = .queued
        guard active.isEmpty else { return }
        let generation = UUID()
        let stagedFile = directory.appending(path: id.uuidString + "." + generation.uuidString + ".partial")
        downloads[index].status = .downloading
        downloads[index].message = nil
        if resumes[id] == nil { downloads[index].received = 0 }
        let delegate = DemoTransferDelegate(
            destination: stagedFile,
            origin: request.url,
            progress: { [weak self] received, expected in
                Task { @MainActor [weak self] in
                    guard let self, active[id]?.generation == generation,
                          let index = downloads.firstIndex(where: { $0.id == id })
                    else { return }
                    downloads[index].received = received
                    downloads[index].expected = expected
                }
            },
            completion: { [weak self] error in
                Task { @MainActor [weak self] in self?.finished(
                    id,
                    generation: generation,
                    stagedFile: stagedFile,
                    error: error
                ) }
            }
        )
        let settings = configuration()
        settings.timeoutIntervalForRequest = 60
        settings.timeoutIntervalForResource = 86400
        let session = URLSession(configuration: settings, delegate: delegate, delegateQueue: nil)
        let task = resumes[id].map { session.downloadTask(withResumeData: $0) } ?? session.downloadTask(with: request)
        active[id] = DemoTransferRun(session: session, task: task, generation: generation)
        task.resume()
    }

    private func finished(_ id: UUID, generation: UUID, stagedFile: URL, error: Error?) {
        guard let running = active[id], running.generation == generation,
              let index = downloads.firstIndex(where: { $0.id == id }) else {
            try? FileManager.default.removeItem(at: stagedFile)
            return
        }
        var transferError = error
        if transferError == nil {
            do { try FileManager.default.moveItem(at: stagedFile, to: fileURL(for: downloads[index])) } catch { transferError = error }
        }
        active[id] = nil
        running.session.finishTasksAndInvalidate()
        let retryResume = transferError != nil && resumes[id] != nil
        resumes[id] = nil
        if retryResume {
            downloads[index].status = .queued
        } else {
            downloads[index].status = transferError == nil ? .completed : .failed
            downloads[index].message = transferError.map(DemoSession.message)
            if transferError == nil { requests[id] = nil }
            save()
        }
        advance()
    }

    private func advance() {
        guard active.isEmpty, let next = downloads.first(where: { $0.status == .queued }) else { return }
        start(next.id)
    }

    func pause(_ id: UUID) {
        guard let running = active.removeValue(forKey: id),
              let index = downloads.firstIndex(where: { $0.id == id }) else { return }
        let generation = UUID()
        pauses[id] = generation
        downloads[index].status = .pausing
        running.task.cancel { [weak self] data in
            running.session.finishTasksAndInvalidate()
            Task { @MainActor [weak self] in
                guard let self, pauses[id] == generation,
                      let index = downloads.firstIndex(where: { $0.id == id }) else { return }
                resumes[id] = data
                pauses[id] = nil
                downloads[index].status = .paused
            }
        }
        advance()
    }

    func cancel(_ id: UUID) {
        guard let index = downloads.firstIndex(where: { $0.id == id }),
              downloads[index].status != .completed else { return }
        active.removeValue(forKey: id)?.session.invalidateAndCancel()
        pauses[id] = nil
        resumes[id] = nil
        downloads[index].status = .cancelled
        advance()
    }

    func cancelActive() {
        for running in active.values { running.session.invalidateAndCancel() }
        active = [:]
        requests = [:]
        resumes = [:]
        pauses = [:]
        for index in downloads.indices
            where downloads[index].status != .completed { downloads[index].status = .cancelled }
    }

    func removeCompleted(_ id: UUID) {
        guard let item = downloads.first(where: { $0.id == id && $0.status == .completed }) else { return }
        do {
            try FileManager.default.removeItem(at: fileURL(for: item))
            downloads.removeAll { $0.id == id }
            save()
        } catch { storageError = String(localized: "The local file could not be removed.") }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(downloads.filter { $0.status == .completed })
            try data.write(to: directory.appending(path: "downloads.json"), options: .atomic)
        } catch {
            storageError =
                String(localized: "The downloaded file was saved, but its library record could not be stored.")
        }
    }
}

private final class DemoTransferDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    let destination: URL
    let origin: URL?
    let progress: @Sendable (Int64, Int64) -> Void
    let completion: @Sendable (Error?) -> Void

    init(
        destination: URL,
        origin: URL?,
        progress: @escaping @Sendable (Int64, Int64) -> Void,
        completion: @escaping @Sendable (Error?) -> Void
    ) {
        self.destination = destination
        self.origin = origin
        self.progress = progress
        self.completion = completion
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        progress(totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard let response = downloadTask.response as? HTTPURLResponse else { throw PlexAPIError.nonHTTPResponse }
            guard (200..<300).contains(response.statusCode) else { throw PlexAPIError.httpStatus(response.statusCode) }
            try FileManager.default.moveItem(at: location, to: destination)
            completion(nil)
        } catch { completion(error) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { completion(error) }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // Match the backend transport: same origin, same scheme, no embedded credentials.
        let target = request.url
        let defaultPort = origin?.scheme?.lowercased() == "https" ? 443 : 80
        let allowed = target?.host?.lowercased() == origin?.host?.lowercased()
            && target?.scheme?.lowercased() == origin?.scheme?.lowercased()
            && (target?.port ?? defaultPort) == (origin?.port ?? defaultPort)
            && target?.user == nil && target?.password == nil
        completionHandler(allowed ? request : nil)
    }
}
