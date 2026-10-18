import Foundation

/// The HTTP methods Plex Media Server uses.
public enum PlexHTTPMethod: String, CaseIterable, Sendable {
    /// Plex uses GET for reads and for some state changes such as scrobbling, PUT and POST for edits, and DELETE for removals.
    case get = "GET", post = "POST", put = "PUT", delete = "DELETE"
}

/// A successful (2xx) raw response.
public struct PlexHTTPResult: Sendable {
    /// The response body, which may be empty.
    public let data: Data
    /// The HTTP status code.
    public let statusCode: Int
    /// The response MIME type, if the server sent one.
    public let contentType: String?

    /// Creates a result, for example in a test double.
    public init(data: Data, statusCode: Int, contentType: String? = nil) {
        self.data = data
        self.statusCode = statusCode
        self.contentType = contentType
    }
}

/// Escape hatch for provider-advertised paths and server capabilities without a typed DTO.
/// Paths remain relative to the configured server and use the same credential/redirect policy.
public protocol PlexServerRequesting: Sendable {
    /// Sends a request to any server-relative path and returns the raw 2xx response.
    /// - Parameters:
    ///   - path: A server-relative path, optionally with a query, such as a key returned by the server.
    ///   - method: The HTTP method.
    ///   - query: Extra query items; `X-Plex-Token` is rejected.
    ///   - body: An optional request body.
    ///   - contentType: The body's MIME type.
    /// - Throws: `PlexAPIError.invalidPath` for unsafe paths, `PlexAPIError.httpStatus` for non-2xx responses.
    func execute(
        path: String,
        method: PlexHTTPMethod,
        query: [URLQueryItem],
        body: Data?,
        contentType: String
    ) async throws -> PlexHTTPResult
    /// An authenticated request for binary content (images, BIF files, original media) at a server-relative path.
    func resourceRequest(path: String) throws -> URLRequest
    /// Builds, without sending, the authenticated request `execute` would send.
    func makeRequest(
        path: String,
        method: PlexHTTPMethod,
        query: [URLQueryItem],
        body: Data?,
        contentType: String
    ) throws -> URLRequest
}

extension PlexAPIService: PlexServerRequesting {
    /// Sends a raw request with the same credential, proxy-prefix and redirect rules as the typed APIs.
    public func execute(
        path: String, method: PlexHTTPMethod = .get, query: [URLQueryItem] = [],
        body: Data? = nil, contentType: String = "application/json"
    ) async throws -> PlexHTTPResult {
        try await executor.execute(makeRequest(
            path: path,
            method: method,
            query: query,
            body: body,
            contentType: contentType
        ))
    }

    /// Builds an authenticated request for a server-relative path; the token travels only in a header.
    public func makeRequest(
        path: String, method: PlexHTTPMethod = .get, query: [URLQueryItem] = [],
        body: Data? = nil, contentType: String = "application/json"
    ) throws -> URLRequest {
        guard PlexClientIdentity.isValidHeaderValue(contentType) else { throw PlexAPIError.invalidConfiguration }
        var request = try configuration.request(path: path, query: query)
        request.httpMethod = method.rawValue
        request.httpBody = body
        if body != nil { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        return request
    }

    /// Useful for authenticated images, BIF data and original streams. Never print its headers.
    public func resourceRequest(path: String) throws -> URLRequest {
        try configuration.request(path: path, accept: "*/*")
    }
}
