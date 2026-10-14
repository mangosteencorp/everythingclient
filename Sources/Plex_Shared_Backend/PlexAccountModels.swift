import Foundation

public struct PlexPIN: Decodable, Sendable, Equatable, Identifiable {
    public let id: String
    public let code: String
    public let expiresIn: Int?
    /// A credential: store securely and never include in logs.
    public let authToken: String?

    enum CodingKeys: String, CodingKey { case id, code, expiresIn, authToken }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.requiredString(forKey: .id)
        code = try values.decode(String.self, forKey: .code)
        expiresIn = try values.flexibleInteger(forKey: .expiresIn)
        let token = try values.decodeIfPresent(String.self, forKey: .authToken)
        authToken = token?.isEmpty == false ? token : nil
    }
}

public struct PlexServerResource: Decodable, Sendable, Identifiable {
    public let clientIdentifier: String
    public let name: String
    public let provides: String
    public let owned: Bool?
    public let connections: [PlexServerConnection]
    private let accessToken: String?
    public var id: String { clientIdentifier }
    public var isServer: Bool {
        provides.split(separator: ",").contains { $0.trimmingCharacters(in: .whitespaces) == "server" }
    }

    /// Select an advertised connection explicitly. Never substitute the account token
    /// for a missing server token; shared servers can use different credentials.
    public func configuration(connectionIndex: Int, identity: PlexClientIdentity) throws -> PlexServerConfiguration {
        guard isServer, connections.indices.contains(connectionIndex), let accessToken else {
            throw PlexAPIError.invalidConfiguration
        }
        return try PlexServerConfiguration(baseURL: connections[connectionIndex].uri, token: accessToken, identity: identity)
    }

    enum CodingKeys: String, CodingKey { case clientIdentifier, name, provides, owned, connections, accessToken }

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

public struct PlexServerConnection: Decodable, Sendable, Equatable {
    public let uri: URL
    public let local: Bool?
    public let relay: Bool?
    public let ipv6: Bool?

    enum CodingKeys: String, CodingKey {
        case uri, local, relay
        case ipv6 = "IPv6"
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uri = try values.decode(URL.self, forKey: .uri)
        local = try values.flexibleBool(forKey: .local)
        relay = try values.flexibleBool(forKey: .relay)
        ipv6 = try values.flexibleBool(forKey: .ipv6)
    }
}
