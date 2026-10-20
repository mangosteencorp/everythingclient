import Foundation

/// How this app identifies itself to plex.tv and Plex Media Server.
/// Sent as `X-Plex-*` headers on every request; Plex shows these values in its device list.
public struct PlexClientIdentity: Sendable, Equatable {
    /// `X-Plex-Client-Identifier`: a stable, per-installation ID. Plex ties sign-in PINs and sessions to it.
    public let identifier: String
    /// `X-Plex-Product`: the app name shown in Plex's authorized-devices list.
    public let product: String
    /// `X-Plex-Version`: the app version.
    public let version: String
    /// `X-Plex-Platform`: the client platform, for example `iOS`.
    public let platform: String

    /// Persist `identifier` in the consuming app so PIN creation and polling use the same identity.
    public init(identifier: String, product: String, version: String, platform: String) throws {
        guard [identifier, product, version, platform].allSatisfy(Self.isValidHeaderValue) else {
            throw PlexAPIError.invalidConfiguration
        }
        self.identifier = identifier
        self.product = product
        self.version = version
        self.platform = platform
    }

    static func isValidHeaderValue(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && value.rangeOfCharacter(from: .controlCharacters) == nil
    }

    var headers: [String: String] {
        [
            "Accept": "application/json",
            "X-Plex-Client-Identifier": identifier,
            "X-Plex-Product": product,
            "X-Plex-Version": version,
            "X-Plex-Platform": platform,
            "X-Plex-Client-Profile-Name": "Generic",
        ]
    }
}

/// A selected Plex Media Server connection: its origin, the server-scoped access token and the client identity.
/// The token is kept internal so it cannot be printed or logged through this type.
public struct PlexServerConfiguration: Sendable {
    /// The server origin, including any reverse-proxy path prefix. Every request path is resolved under it.
    public let baseURL: URL
    /// The client identity sent with every request to this server.
    public let identity: PlexClientIdentity
    /// The server's `machineIdentifier`; required for `server://` URIs used by playlists, collections and play queues.
    public let machineIdentifier: String?
    // Deliberately not exposed as a printable public property.
    let token: String

    /// Use the resource's server access token, which may differ from the plex.tv account token.
    public init(baseURL: URL, token: String, identity: PlexClientIdentity, machineIdentifier: String? = nil) throws {
        try PlexURLBuilder.validateBaseURL(baseURL)
        guard PlexClientIdentity.isValidHeaderValue(token) else { throw PlexAPIError.invalidConfiguration }
        self.baseURL = baseURL
        self.token = token
        self.identity = identity
        self.machineIdentifier = machineIdentifier
    }

    /// A persistable snapshot for a credential store. It contains the server token.
    public func credential(name: String) -> PlexServerCredential {
        PlexServerCredential(name: name, baseURL: baseURL, machineIdentifier: machineIdentifier, token: token)
    }

    func request(path: String, query: [URLQueryItem] = [], accept: String = "application/json") throws -> URLRequest {
        var request = URLRequest(url: try PlexURLBuilder.url(base: baseURL, path: path, query: query))
        request.cachePolicy = .reloadIgnoringLocalCacheData
        for (name, value) in identity.headers { request.setValue(value, forHTTPHeaderField: name) }
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        return request
    }
}

/// The last working server connection, kept so an app can reopen it (or its offline cache) after relaunch.
/// Contains a credential: store it in the Keychain and never log it.
public struct PlexServerCredential: Codable, Sendable, Equatable {
    /// The server's display name.
    public let name: String
    /// The origin that last connected successfully.
    public let baseURL: URL
    /// The server's `machineIdentifier`, also used as the offline cache and watch-sync scope.
    public let machineIdentifier: String?
    let token: String

    /// Rebuilds a server configuration from the saved credential.
    /// - Parameter identity: The client identity to send; reuse the persisted one.
    /// - Throws: `PlexAPIError.invalidConfiguration` when the saved URL or token is no longer valid.
    public func configuration(identity: PlexClientIdentity) throws -> PlexServerConfiguration {
        try PlexServerConfiguration(baseURL: baseURL, token: token, identity: identity, machineIdentifier: machineIdentifier)
    }
}

enum PlexURLBuilder {
    static func validateBaseURL(_ url: URL) throws {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              ["http", "https"].contains(components.scheme?.lowercased()),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              isSafePath(components.percentEncodedPath)
        else { throw PlexAPIError.invalidConfiguration }
    }

    static func segment(_ value: String) throws -> String {
        guard !value.isEmpty, value != ".", value != "..", !value.contains("/"), !value.contains("\\"),
              value.rangeOfCharacter(from: .controlCharacters) == nil,
              let encoded = value
              .addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-._~")))
        else { throw PlexAPIError.invalidPath }
        return encoded
    }

    /// Plex keys are root-relative to the configured server, including any reverse-proxy base path.
    /// Refuse URLs that could send the server token to another origin or escape the base path.
    static func url(base: URL, path: String, query: [URLQueryItem] = []) throws -> URL {
        guard path.hasPrefix("/"), !path.hasPrefix("//"),
              let key = URLComponents(string: path), key.scheme == nil, key.host == nil,
              key.user == nil, key.password == nil, key.fragment == nil,
              isSafePath(key.percentEncodedPath),
              !((key.queryItems ?? []) + query).contains(where: { $0.name.lowercased() == "x-plex-token" }),
              var result = URLComponents(url: base, resolvingAgainstBaseURL: false)
        else { throw PlexAPIError.invalidPath }
        let prefix = result.percentEncodedPath.hasSuffix("/") ? String(result.percentEncodedPath.dropLast()) : result
            .percentEncodedPath
        result.percentEncodedPath = prefix + key.percentEncodedPath
        // Keep existing percent escapes and '+' in server keys intact.
        if query.isEmpty {
            result.percentEncodedQuery = key.percentEncodedQuery
        } else {
            var extra = URLComponents()
            extra.queryItems = query
            let encodedQuery = extra.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            result.percentEncodedQuery = [key.percentEncodedQuery, encodedQuery].compactMap { $0 }
                .joined(separator: "&")
        }
        guard let url = result.url else { throw PlexAPIError.invalidPath }
        return url
    }

    private static func isSafePath(_ path: String) -> Bool {
        var decoded = path
        // Check nested escaping as well as the path the server is likely to decode once.
        for _ in 0..<4 {
            guard !decoded.contains("\\"), decoded.rangeOfCharacter(from: .controlCharacters) == nil,
                  !decoded.split(separator: "/", omittingEmptySubsequences: false)
                  .contains(where: { $0 == "." || $0 == ".." })
            else { return false }
            guard let next = decoded.removingPercentEncoding else { return false }
            if next == decoded { return true }
            decoded = next
        }
        return false
    }
}
