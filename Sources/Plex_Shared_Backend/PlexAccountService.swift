import Foundation

/// plex.tv sign-in and server discovery.
public protocol PlexAccountServing: Sendable {
    /// Creates a sign-in PIN to show the user and authorize in the browser.
    func createPIN() async throws -> PlexPIN
    /// Checks a PIN once; `authToken` is set after the user authorizes it.
    /// - Throws: `PlexAPIError.pinExpired` once the PIN is gone.
    func pin(id: String) async throws -> PlexPIN
    /// The browser page where the user signs in and approves a PIN.
    func authorizationURL(code: String) throws -> URL
    /// Media servers this account can reach, each with its own access token and connections.
    func servers(accountToken: String) async throws -> [PlexServerResource]
}

/// PIN authentication and resource discovery. The app owns browser presentation,
/// polling cadence/cancellation, credential storage, and connection selection.
public struct PlexAccountService: PlexAccountServing {
    private let identity: PlexClientIdentity
    private let executor: PlexRequestExecutor

    /// Creates an account service.
    /// - Parameters:
    ///   - identity: The persisted client identity; PIN creation and polling must use the same one.
    ///   - transport: Performs the HTTP calls.
    public init(identity: PlexClientIdentity, transport: any PlexHTTPTransport = PlexURLSessionTransport()) {
        self.identity = identity
        executor = PlexRequestExecutor(transport: transport)
    }

    /// `POST https://plex.tv/api/v2/pins?strong=true`.
    public func createPIN() async throws -> PlexPIN {
        var request = try accountRequest(path: "/pins", query: [URLQueryItem(name: "strong", value: "true")])
        request.httpMethod = "POST"
        return try await executor.decode(PlexPIN.self, request: request)
    }

    /// One poll. A nil authToken means authorization is still pending.
    public func pin(id: String) async throws -> PlexPIN {
        do {
            return try await executor.decode(
                PlexPIN.self,
                request: accountRequest(path: "/pins/\(try PlexURLBuilder.segment(id))")
            )
        } catch PlexAPIError.httpStatus(404), PlexAPIError.httpStatus(410) {
            throw PlexAPIError.pinExpired
        }
    }

    /// `https://app.plex.tv/auth#?clientID=…&code=…&context[device][product]=…`.
    /// - Throws: `PlexAPIError.invalidConfiguration` for an empty or unsafe code.
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
        components.percentEncodedFragment = "?" + (query.percentEncodedQuery ?? "").replacingOccurrences(
            of: "+",
            with: "%2B"
        )
        guard let url = components.url else { throw PlexAPIError.invalidConfiguration }
        return url
    }

    /// `GET https://plex.tv/api/v2/resources?includeHttps=1&includeRelay=1&includeIPv6=1`, keeping only resources that provide `server`.
    public func servers(accountToken: String) async throws -> [PlexServerResource] {
        let query = ["includeHttps", "includeRelay", "includeIPv6"].map { URLQueryItem(name: $0, value: "1") }
        let request = try accountRequest(path: "/resources", query: query, token: accountToken)
        let resources = try await executor.decode([PlexServerResource].self, request: request)
        return resources.filter(\.isServer)
    }

    /// `GET https://clients.plex.tv/api/v2/user`.
    public func user(accountToken: String) async throws -> PlexAccountUser {
        try await executor.decode(PlexAccountUser.self, request: accountRequest(path: "/user", token: accountToken, clientsAPI: true))
    }

    /// `GET https://clients.plex.tv/api/v2/home/users`.
    public func homeUsers(accountToken: String) async throws -> [PlexAccountUser] {
        struct Home: Decodable, Sendable { let users: [PlexAccountUser] }
        return try await executor.decode(Home.self, request: accountRequest(path: "/home/users", token: accountToken, clientsAPI: true))
            .users
    }

    /// `POST https://clients.plex.tv/api/v2/home/users/{uuid}/switch`, with `pin` for protected profiles.
    /// Never log this request: the PIN is a query parameter.
    public func switchUser(uuid: String, pin: String? = nil, accountToken: String) async throws -> PlexAccountSession {
        var request = try accountRequest(
            path: "/home/users/\(PlexURLBuilder.segment(uuid))/switch",
            query: pin.flatMap { $0.isEmpty ? nil : [URLQueryItem(name: "pin", value: $0)] } ?? [],
            token: accountToken,
            clientsAPI: true
        )
        request.httpMethod = "POST"
        request.setValue("0", forHTTPHeaderField: "Content-Length")
        return try await executor.decode(PlexAccountSession.self, request: request)
    }

    private func accountRequest(path: String, query: [URLQueryItem] = [], token: String? = nil, clientsAPI: Bool = false) throws -> URLRequest {
        guard let base = URL(string: clientsAPI ? "https://clients.plex.tv/api/v2" : "https://plex.tv/api/v2") else { throw PlexAPIError.invalidConfiguration }
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
