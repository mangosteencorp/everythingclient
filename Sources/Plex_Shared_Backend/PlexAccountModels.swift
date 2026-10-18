import Foundation

/// A sign-in PIN from plex.tv.
public struct PlexPIN: Decodable, Sendable, Equatable, Identifiable {
    /// The PIN ID to poll with `pin(id:)`.
    public let id: String
    /// The code the user sees and approves.
    public let code: String
    /// Seconds until the PIN expires.
    public let expiresIn: Int?
    /// A credential: store securely and never include in logs.
    public let authToken: String?

    enum CodingKeys: String, CodingKey { case id, code, expiresIn, authToken }

    /// Decodes a PIN; an empty `authToken` counts as not yet authorized.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.requiredString(forKey: .id)
        code = try values.decode(String.self, forKey: .code)
        expiresIn = try values.flexibleInteger(forKey: .expiresIn)
        let token = try values.decodeIfPresent(String.self, forKey: .authToken)
        authToken = token?.isEmpty == false ? token : nil
    }
}

/// A media server from plex.tv resource discovery, with its own access token.
public struct PlexServerResource: Decodable, Sendable, Identifiable {
    /// The server's machine identifier.
    public let clientIdentifier: String
    /// The server name.
    public let name: String
    /// Comma-separated capabilities, such as `server` or `player`.
    public let provides: String
    /// Whether the signed-in account owns the server (false for shared servers).
    public let owned: Bool?
    /// Advertised addresses; `PlexServerConnector` picks a working one.
    public let connections: [PlexServerConnection]
    private let accessToken: String?
    /// The machine identifier.
    public var id: String { clientIdentifier }
    /// Whether the resource provides `server`.
    public var isServer: Bool {
        provides.split(separator: ",").contains { $0.trimmingCharacters(in: .whitespaces) == "server" }
    }

    /// Select an advertised connection explicitly. Never substitute the account token
    /// for a missing server token; shared servers can use different credentials.
    public func configuration(connectionIndex: Int, identity: PlexClientIdentity) throws -> PlexServerConfiguration {
        guard isServer, connections.indices.contains(connectionIndex), let accessToken else {
            throw PlexAPIError.invalidConfiguration
        }
        return try PlexServerConfiguration(
            baseURL: connections[connectionIndex].uri, token: accessToken, identity: identity, machineIdentifier: clientIdentifier
        )
    }

    enum CodingKeys: String, CodingKey { case clientIdentifier, name, provides, owned, connections, accessToken }

    /// Decodes a resource.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        clientIdentifier = try values.requiredString(forKey: .clientIdentifier)
        name = try values.decode(String.self, forKey: .name)
        provides = try values.decode(String.self, forKey: .provides)
        owned = try values.flexibleBool(forKey: .owned)
        connections = try values.flexibleArray(forKey: .connections)
        accessToken = try values.decodeIfPresent(String.self, forKey: .accessToken)
    }
}

/// One advertised address of a server.
public struct PlexServerConnection: Decodable, Sendable, Equatable {
    /// The connection origin.
    public let uri: URL
    /// Whether it is on the server's local network.
    public let local: Bool?
    /// Whether it goes through Plex's bandwidth-limited relay.
    public let relay: Bool?
    /// Whether it is an IPv6 address.
    public let ipv6: Bool?

    enum CodingKeys: String, CodingKey {
        case uri, local, relay
        case ipv6 = "IPv6"
    }

    /// Decodes a connection.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uri = try values.decode(URL.self, forKey: .uri)
        local = try values.flexibleBool(forKey: .local)
        relay = try values.flexibleBool(forKey: .relay)
        ipv6 = try values.flexibleBool(forKey: .ipv6)
    }
}
