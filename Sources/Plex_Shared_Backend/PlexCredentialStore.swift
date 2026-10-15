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
    private let service: String
    private let account: String

    /// Creates a store for one Keychain item.
    /// - Parameters:
    ///   - service: Usually the app's bundle identifier.
    ///   - account: The item name within that service.
    public init(service: String, account: String = "plex-session") {
        self.service = service
        self.account = account
    }

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    /// Reads and decodes the Keychain item.
    public func load() -> PlexStoredSession? {
        var result: AnyObject?
        var search = query
        search[kSecReturnData as String] = true
        guard SecItemCopyMatching(search as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
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
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(attributes) { $1 } as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw PlexAPIError.invalidConfiguration }
    }

    /// Deletes the Keychain item.
    public func clear() { SecItemDelete(query as CFDictionary) }
}
