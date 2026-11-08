import Foundation

/// The only dependency that performs network I/O; mocks can return fixture bytes and HTTP responses.
public protocol RSSHTTPTransport: Sendable {
    /// Performs one HTTP request and returns the raw body and response, without interpreting the status code.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// The default `URLSession` transport.
public struct RSSURLSessionTransport: RSSHTTPTransport {
    private let session: URLSession

    /// Feeds are public and unauthenticated, so the shared session is the default.
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Sends the request through the underlying `URLSession`.
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
