import Foundation
@testable import Plex_Shared_Backend
import Security
import Testing

struct PlexCredentialStoreTests {
    @Test func preservesDefaultItemNameAndDefaultAccessGroup() {
        let store = PlexKeychainCredentialStore(service: "example.plex")
        #expect(store.service == "example.plex")
        #expect(store.account == "plex-session")
        #expect(store.accessGroup == nil)
        #expect(store.query[kSecClass as String] as? String == kSecClassGenericPassword as String)
        #expect(store.query[kSecAttrService as String] as? String == store.service)
        #expect(store.query[kSecAttrAccount as String] as? String == store.account)
        #expect(store.query[kSecAttrAccessGroup as String] == nil)
    }

    @Test func targetsTheChosenServiceItemAndAccessGroup() {
        let store = PlexKeychainCredentialStore(service: "example.shared", account: "plex-work", accessGroup: "TEAM.example.shared")
        #expect(store.service == "example.shared")
        #expect(store.account == "plex-work")
        #expect(store.accessGroup == "TEAM.example.shared")
        #expect(store.query[kSecAttrService as String] as? String == store.service)
        #expect(store.query[kSecAttrAccount as String] as? String == store.account)
        #expect(store.query[kSecAttrAccessGroup as String] as? String == store.accessGroup)
    }

    @Test func savesUpdatesAndClearsTheChosenSession() throws {
        let store = PlexKeychainCredentialStore(service: "PlexCredentialStoreTests.\(UUID().uuidString)", account: "custom-session")
        defer { store.clear() }
        #expect(store.load() == nil)
        let initial = PlexStoredSession(accountToken: "first-token", accountName: "First profile")
        try store.save(initial)
        #expect(store.load() == initial)
        let updated = PlexStoredSession(accountToken: "second-token", accountName: "Second profile")
        try store.save(updated)
        #expect(store.load() == updated)
        store.clear()
        #expect(store.load() == nil)
    }

    @Test func separatesAccountsAndServicesWhenSavingAndClearing() throws {
        let service = "PlexCredentialStoreTests.\(UUID().uuidString)"
        let primary = PlexKeychainCredentialStore(service: service, account: "primary")
        let otherAccount = PlexKeychainCredentialStore(service: service, account: "secondary")
        let otherService = PlexKeychainCredentialStore(service: service + ".other", account: "primary")
        defer {
            primary.clear()
            otherAccount.clear()
            otherService.clear()
        }
        let first = PlexStoredSession(accountToken: "first-token")
        let second = PlexStoredSession(accountToken: "second-token")
        let third = PlexStoredSession(accountToken: "third-token")
        try primary.save(first)
        try otherAccount.save(second)
        try otherService.save(third)
        #expect(primary.load() == first)
        #expect(otherAccount.load() == second)
        #expect(otherService.load() == third)
        primary.clear()
        #expect(primary.load() == nil)
        #expect(otherAccount.load() == second)
        #expect(otherService.load() == third)
    }
}
