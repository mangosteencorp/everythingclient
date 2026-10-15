import Foundation

/// A plex.tv account or Plex Home profile.
public struct PlexAccountUser: Decodable, Identifiable, Sendable {
    /// The account ID.
    public let id: String
    /// The profile UUID, used to switch to it.
    public let uuid: String?
    /// The display name, falling back to friendly name, username and then ID.
    public let title: String
    /// Whether switching to this profile requires its PIN.
    public let isProtected: Bool

    enum CodingKeys: String, CodingKey { case id, uuid, title, username, friendlyName, protected }
    /// Decodes `/user` and `/home/users` entries.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.requiredString(forKey: .id)
        uuid = try values.flexibleString(forKey: .uuid)
        title = try values.decodeIfPresent(String.self, forKey: .title)
            ?? values.decodeIfPresent(String.self, forKey: .friendlyName)
            ?? values.decodeIfPresent(String.self, forKey: .username) ?? id
        isProtected = try values.flexibleBool(forKey: .protected) ?? false
    }
}

/// Contains a credential. Consumers must not render or log this value.
public struct PlexAccountSession: Decodable, Sendable {
    /// The account token for the profile switched to.
    public let authToken: String
}

/// The signed-in account and its Plex Home profiles.
public protocol PlexAccountProfileServing: Sendable {
    /// The account the token belongs to.
    func user(accountToken: String) async throws -> PlexAccountUser
    /// Profiles in the account's Plex Home.
    func homeUsers(accountToken: String) async throws -> [PlexAccountUser]
    /// Switches to a Home profile and returns that profile's token. Rediscover servers with it afterwards.
    func switchUser(uuid: String, pin: String?, accountToken: String) async throws -> PlexAccountSession
}

extension PlexAccountService: PlexAccountProfileServing {}
