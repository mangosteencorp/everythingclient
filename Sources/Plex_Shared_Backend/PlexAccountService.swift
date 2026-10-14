import Foundation

public protocol PlexAccountServing: Sendable {
    func createPIN() async throws -> PlexPIN
    func pin(id: String) async throws -> PlexPIN
    func authorizationURL(code: String) throws -> URL
    func servers(accountToken: String) async throws -> [PlexServerResource]
}

/// PIN authentication and resource discovery. The app owns browser presentation,
/// polling cadence/cancellation, credential storage, and connection selection.
public struct PlexAccountService: PlexAccountServing {
    private let identity: PlexClientIdentity
    private let executor: PlexRequestExecutor

    public init(identity: PlexClientIdentity, transport: any PlexHTTPTransport = PlexURLSessionTransport()) {
        self.identity = identity
        executor = PlexRequestExecutor(transport: transport)
    }

    public func createPIN() async throws -> PlexPIN {
        var request = try accountRequest(path: "/pins", query: [URLQueryItem(name: "strong", value: "true")])
        request.httpMethod = "POST"
        return try await executor.decode(PlexPIN.self, request: request)
    }

    /// One poll. A nil authToken means authorization is still pending.
    public func pin(id: String) async throws -> PlexPIN {
        do {
            return try await executor.decode(PlexPIN.self, request: accountRequest(path: "/pins/\(try PlexURLBuilder.segment(id))"))
        } catch PlexAPIError.httpStatus(404), PlexAPIError.httpStatus(410) {
            throw PlexAPIError.pinExpired
        }
    }

    public func authorizationURL(code: String) throws -> URL {
        guard PlexClientIdentity.isValidHeaderValue(code) else { throw PlexAPIError.invalidConfiguration }
        var query = URLComponents()
        query.queryItems = [
            URLQueryItem(name: "clientID", value: identity.identifier),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "context[device][product]", value: identity.product),
        ]
        var components = URLComponents()
        components.scheme = "https"
        components.host = "app.plex.tv"
        components.path = "/auth"
        // The Plex auth app reads query parameters inside the fragment.
        components.percentEncodedFragment = "?" + (query.percentEncodedQuery ?? "").replacingOccurrences(of: "+", with: "%2B")
        guard let url = components.url else { throw PlexAPIError.invalidConfiguration }
        return url
    }

    public func servers(accountToken: String) async throws -> [PlexServerResource] {
        let query = ["includeHttps", "includeRelay", "includeIPv6"].map { URLQueryItem(name: $0, value: "1") }
        let request = try accountRequest(path: "/resources", query: query, token: accountToken)
        let resources = try await executor.decode([PlexServerResource].self, request: request)
        return resources.filter(\.isServer)
    }

    private func accountRequest(path: String, query: [URLQueryItem] = [], token: String? = nil) throws -> URLRequest {
        guard let base = URL(string: "https://plex.tv/api/v2") else { throw PlexAPIError.invalidConfiguration }
        var request = URLRequest(url: try PlexURLBuilder.url(base: base, path: path, query: query))
        request.cachePolicy = .reloadIgnoringLocalCacheData
        for (name, value) in identity.headers { request.setValue(value, forHTTPHeaderField: name) }
        if let token {
            guard PlexClientIdentity.isValidHeaderValue(token) else { throw PlexAPIError.invalidConfiguration }
            request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        }
        return request
    }
}
