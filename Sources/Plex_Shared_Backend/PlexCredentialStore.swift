import Foundation
import Security

/// What an app needs to restore a Plex session after relaunch, online or offline.
/// Contains credentials: keep it in the Keychain and never log it.
public struct PlexStoredSession: Codable, Sendable, Equatable {
    /// The plex.tv account token, absent for manual server connections.
    public var accountToken: String?
    /// The signed-in profile's name, for display before reconnecting.
    public var accountName: String?
    /// The last server that connected.
    public var server: PlexServerCredential?

    /// Creates a session snapshot.
    public init(accountToken: String? = nil, accountName: String? = nil, server: PlexServerCredential? = nil) {
        self.accountToken = accountToken
        self.accountName = accountName
        self.server = server
    }
}

/// Persists a `PlexStoredSession`. Implement it with another secure store if needed.
public protocol PlexCredentialStoring: Sendable {
    /// The saved session, or nil when none is saved or it can't be read.
    func load() -> PlexStoredSession?
    /// Replaces the saved session.
    func save(_ session: PlexStoredSession) throws
    /// Removes the saved session, for example on sign-out.
    func clear()
}

/// A generic-password Keychain item, readable after first unlock and never synced to other devices.
public struct PlexKeychainCredentialStore: PlexCredentialStoring {
    /// The namespace containing this session item, usually the app's bundle identifier.
    public let service: String
    /// The session item's name within its service.
    public let account: String
    /// The entitled Keychain access group, or nil to use the app's default group.
    public let accessGroup: String?
    private let keychain: any PlexKeychainAccessing

    /// Creates a store for one Keychain item.
    /// - Parameters:
    ///   - service: Usually the app's bundle identifier.
    ///   - account: The item name within that service.
    ///   - accessGroup: An access group from the app's Keychain Sharing entitlement, if needed.
    public init(service: String, account: String = "plex-session", accessGroup: String? = nil) {
        self.init(service: service, account: account, accessGroup: accessGroup, keychain: PlexSecurityKeychain())
    }

    init(service: String, account: String = "plex-session", accessGroup: String? = nil, keychain: any PlexKeychainAccessing) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
        self.keychain = keychain
    }

    private var query: [String: Any] {
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        return query
    }

    /// Reads and decodes the Keychain item.
    public func load() -> PlexStoredSession? {
        var search = query
        search[kSecReturnData as String] = true
        let (status, result) = keychain.data(matching: search)
        guard status == errSecSuccess, let data = result else { return nil }
        return try? JSONDecoder().decode(PlexStoredSession.self, from: data)
    }

    /// Adds or updates the Keychain item.
    /// - Throws: `PlexAPIError.invalidConfiguration` when the Keychain rejects the write.
    public func save(_ session: PlexStoredSession) throws {
        let data = try JSONEncoder().encode(session)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        var status = keychain.update(matching: query, attributes: attributes)
        if status == errSecItemNotFound {
            status = keychain.add(query.merging(attributes) { $1 })
        }
        guard status == errSecSuccess else { throw PlexAPIError.invalidConfiguration }
    }

    /// Deletes the Keychain item.
    public func clear() { keychain.delete(matching: query) }
}

protocol PlexKeychainAccessing: Sendable {
    func data(matching query: [String: Any]) -> (OSStatus, Data?)
    func update(matching query: [String: Any], attributes: [String: Any]) -> OSStatus
    func add(_ attributes: [String: Any]) -> OSStatus
    func delete(matching query: [String: Any])
}

struct PlexSecurityKeychain: PlexKeychainAccessing {
    func data(matching query: [String: Any]) -> (OSStatus, Data?) {
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return (status, result as? Data)
    }

    func update(matching query: [String: Any], attributes: [String: Any]) -> OSStatus {
        SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }

    func add(_ attributes: [String: Any]) -> OSStatus { SecItemAdd(attributes as CFDictionary, nil) }

    func delete(matching query: [String: Any]) { SecItemDelete(query as CFDictionary) }
}
