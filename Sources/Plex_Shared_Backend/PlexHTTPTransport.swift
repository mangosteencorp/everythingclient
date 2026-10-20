import Foundation

/// The only dependency that performs network I/O; mocks can return fixture bytes and HTTP responses.
public protocol PlexHTTPTransport: Sendable {
    /// Performs one HTTP request and returns the raw body and response, without interpreting the status code.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// The default `URLSession` transport. It refuses redirects that change scheme, host or port, so Plex's
/// header credentials can never be forwarded to another origin.
public struct PlexURLSessionTransport: PlexHTTPTransport {
    private let session: URLSession

    /// Cross-origin redirects are refused because Plex uses a custom credential header.
    public init(configuration: URLSessionConfiguration = .ephemeral) {
        session = URLSession(configuration: configuration, delegate: PlexRedirectPolicy(), delegateQueue: nil)
    }

    /// Sends the request through the underlying `URLSession`.
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

final class PlexRedirectPolicy: NSObject, URLSessionTaskDelegate {
    static func permits(from original: URL?, to destination: URL?) -> Bool {
        guard let original, let destination,
              destination.user == nil, destination.password == nil,
              let scheme = original.scheme?.lowercased(), ["http", "https"].contains(scheme),
              scheme == destination.scheme?.lowercased(),
              original.host?.lowercased() == destination.host?.lowercased()
        else { return false }
        let defaultPort = scheme == "https" ? 443 : 80
        return (original.port ?? defaultPort) == (destination.port ?? defaultPort)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(Self.permits(from: task.originalRequest?.url, to: request.url) ? request : nil)
    }
}

struct PlexRequestExecutor: Sendable {
    let transport: any PlexHTTPTransport

    func decode<Value: Decodable & Sendable>(_ type: Value.Type, request: URLRequest) async throws -> Value {
        let result = try await execute(request)
        return try JSONDecoder().decode(type, from: result.data)
    }

    func execute(_ request: URLRequest) async throws -> PlexHTTPResult {
        try Task.checkCancellation()
        let (data, response) = try await transport.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw PlexAPIError.nonHTTPResponse }
        guard (200..<300).contains(response.statusCode) else { throw PlexAPIError.httpStatus(response.statusCode) }
        return PlexHTTPResult(data: data, statusCode: response.statusCode, contentType: response.mimeType)
    }
}
