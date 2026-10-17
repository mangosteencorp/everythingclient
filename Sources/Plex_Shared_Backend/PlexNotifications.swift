import Foundation

/// One server-sent event, such as `timeline`, `playing`, `activity` or `update.statechange`.
public struct PlexServerEvent: Sendable, Equatable {
    /// The `event:` name, or `message` when the server sends none.
    public let name: String
    /// The JSON payload.
    public let data: Data
}

/// A source of server-sent-event lines.
public protocol PlexEventStreaming: Sendable {
    /// Streams the response line by line, including the blank lines that end each event.
    func lines(for request: URLRequest) -> AsyncThrowingStream<String, Error>
}

extension PlexEventStreaming {
    /// Groups `event:`/`data:` lines into events. Build the request with `PlexAPIService.notificationsRequest()`.
    public func events(for request: URLRequest) -> AsyncThrowingStream<PlexServerEvent, Error> {
        let lines = lines(for: request)
        return AsyncThrowingStream(bufferingPolicy: .bufferingNewest(60)) { continuation in
            let task = Task {
                var name = "message"
                var data: [String] = []
                do {
                    for try await line in lines {
                        if line.hasPrefix("event:") {
                            name = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("data:") {
                            data.append(line.dropFirst(5).trimmingCharacters(in: .whitespaces))
                        } else if line.isEmpty, !data.isEmpty {
                            continuation.yield(PlexServerEvent(name: name, data: Data(data.joined(separator: "\n").utf8)))
                            name = "message"
                            data = []
                        }
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Event-source notifications. The consumer owns start/stop and interprets event payloads.
public struct PlexEventSource: PlexEventStreaming {
    private let logger: PlexCurlLogger?

    /// Creates an event source.
    /// - Parameter logger: Logs the stream request as a `curl` command when enabled.
    public init(logger: PlexCurlLogger? = nil) {
        self.logger = logger
    }

    /// Opens the stream with the same redirect restrictions as `PlexURLSessionTransport`; cancel the iterating task to close it.
    public func lines(for request: URLRequest) -> AsyncThrowingStream<String, Error> {
        logger?.log(request)
        return AsyncThrowingStream(bufferingPolicy: .bufferingNewest(60)) { continuation in
            let session = URLSession(configuration: .ephemeral, delegate: PlexRedirectPolicy(), delegateQueue: nil)
            let task = Task {
                defer { session.invalidateAndCancel() }
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let response = response as? HTTPURLResponse else { throw PlexAPIError.nonHTTPResponse }
                    guard (200..<300).contains(response.statusCode)
                    else { throw PlexAPIError.httpStatus(response.statusCode) }
                    // AsyncLineSequence drops empty lines, so rebuild the blank separators events rely on.
                    var line = Data()
                    for try await byte in bytes {
                        try Task.checkCancellation()
                        guard byte == UInt8(ascii: "\n") else { line.append(byte); continue }
                        continuation.yield((String(bytes: line, encoding: .utf8) ?? "").trimmingCharacters(in: .newlines))
                        line.removeAll()
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
            continuation.onTermination = { _ in task.cancel(); session.invalidateAndCancel() }
        }
    }
}
