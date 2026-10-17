import Foundation
@testable import Plex_Shared_Backend
import Security
import Synchronization
import Testing

struct PlexCredentialStoreTests {
    @Test func preservesDefaultItemNameAndDefaultAccessGroup() throws {
        let keychain = PlexStubKeychain()
        let store = PlexKeychainCredentialStore(service: "example.plex", keychain: keychain)
        #expect(store.service == "example.plex")
        #expect(store.account == "plex-session")
        #expect(store.accessGroup == nil)
        #expect(store.load() == nil)
        let call = try #require(keychain.calls.first)
        #expect(call.item.itemClass == kSecClassGenericPassword as String)
        #expect(call.item.service == store.service)
        #expect(call.item.account == store.account)
        #expect(call.item.accessGroup == nil)
        #expect(call.returnsData == true)
    }

    @Test func targetsTheChosenServiceItemAndAccessGroupForEveryOperation() throws {
        let keychain = PlexStubKeychain()
        let store = PlexKeychainCredentialStore(service: "example.shared", account: "plex-work", accessGroup: "TEAM.example.shared", keychain: keychain)
        #expect(store.service == "example.shared")
        #expect(store.account == "plex-work")
        #expect(store.accessGroup == "TEAM.example.shared")
        let session = PlexStoredSession(accountToken: "account-token")
        try store.save(session)
        #expect(store.load() == session)
        try store.save(session)
        store.clear()
        #expect(keychain.calls.map(\.method) == [.update, .add, .read, .update, .delete])
        for call in keychain.calls {
            #expect(call.item.itemClass == kSecClassGenericPassword as String)
            #expect(call.item.service == store.service)
            #expect(call.item.account == store.account)
            #expect(call.item.accessGroup == store.accessGroup)
        }
    }

    @Test func savesUpdatesAndClearsTheChosenSession() throws {
        let keychain = PlexStubKeychain()
        let store = PlexKeychainCredentialStore(service: "example.plex", account: "custom-session", keychain: keychain)
        #expect(store.load() == nil)
        let initial = PlexStoredSession(accountToken: "first-token", accountName: "First profile")
        try store.save(initial)
        #expect(store.load() == initial)
        let updated = PlexStoredSession(accountToken: "second-token", accountName: "Second profile")
        try store.save(updated)
        #expect(store.load() == updated)
        store.clear()
        #expect(store.load() == nil)
        #expect(keychain.calls.map(\.method) == [.read, .update, .add, .read, .update, .read, .delete, .read])
        let writes = keychain.calls.filter { $0.method == .add || $0.method == .update }
        #expect(writes.allSatisfy { $0.accessibility == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String })
        #expect(try JSONDecoder().decode(PlexStoredSession.self, from: #require(writes.last?.data)) == updated)
    }

    @Test func separatesAccountsServicesAndAccessGroupsWhenSavingAndClearing() throws {
        let keychain = PlexStubKeychain()
        let primary = PlexKeychainCredentialStore(service: "example.plex", account: "primary", accessGroup: "TEAM.group-one", keychain: keychain)
        let otherAccount = PlexKeychainCredentialStore(service: primary.service, account: "secondary", accessGroup: primary.accessGroup, keychain: keychain)
        let otherService = PlexKeychainCredentialStore(service: "example.other", account: primary.account, accessGroup: primary.accessGroup, keychain: keychain)
        let otherGroup = PlexKeychainCredentialStore(service: primary.service, account: primary.account, accessGroup: "TEAM.group-two", keychain: keychain)
        let stores = [primary, otherAccount, otherService, otherGroup]
        let sessions = stores.indices.map { PlexStoredSession(accountToken: "token-\($0)") }
        for (store, session) in zip(stores, sessions) { try store.save(session) }
        for (store, session) in zip(stores, sessions) { #expect(store.load() == session) }
        primary.clear()
        #expect(primary.load() == nil)
        for (store, session) in zip(stores.dropFirst(), sessions.dropFirst()) { #expect(store.load() == session) }
    }

    @Test(arguments: [errSecMissingEntitlement, errSecAuthFailed])
    func rejectedUpdateDoesNotAttemptAnAdd(status: OSStatus) {
        let keychain = PlexStubKeychain(updateStatus: status)
        let store = PlexKeychainCredentialStore(service: "example.plex", keychain: keychain)
        #expect(throws: PlexAPIError.invalidConfiguration) { try store.save(PlexStoredSession(accountToken: "token")) }
        #expect(keychain.calls.map(\.method) == [.update])
    }

    @Test func rejectedAddReportsAnInvalidConfiguration() {
        let keychain = PlexStubKeychain(addStatus: errSecMissingEntitlement)
        let store = PlexKeychainCredentialStore(service: "example.plex", keychain: keychain)
        #expect(throws: PlexAPIError.invalidConfiguration) { try store.save(PlexStoredSession(accountToken: "token")) }
        #expect(keychain.calls.map(\.method) == [.update, .add])
    }

    @Test func unreadableAndMalformedItemsDoNotRestoreASession() throws {
        let keychain = PlexStubKeychain()
        let store = PlexKeychainCredentialStore(service: "example.plex", keychain: keychain)
        try store.save(PlexStoredSession(accountToken: "token"))
        keychain.state.withLock { $0.readStatus = errSecMissingEntitlement }
        #expect(store.load() == nil)
        keychain.state.withLock { state in
            state.readStatus = nil
            state.items = state.items.mapValues { _ in Data("invalid JSON".utf8) }
        }
        #expect(store.load() == nil)
    }
}

private final class PlexStubKeychain: PlexKeychainAccessing {
    enum Method: Sendable { case read, update, add, delete }

    struct Item: Hashable, Sendable {
        let itemClass: String?
        let service: String?
        let account: String?
        let accessGroup: String?

        init(_ query: [String: Any]) {
            itemClass = query[kSecClass as String] as? String
            service = query[kSecAttrService as String] as? String
            account = query[kSecAttrAccount as String] as? String
            accessGroup = query[kSecAttrAccessGroup as String] as? String
        }
    }

    struct Call: Sendable {
        let method: Method
        let item: Item
        let data: Data?
        let accessibility: String?
        let returnsData: Bool?

        init(_ method: Method, query: [String: Any], attributes: [String: Any] = [:]) {
            self.method = method
            item = Item(query)
            data = attributes[kSecValueData as String] as? Data
            accessibility = attributes[kSecAttrAccessible as String] as? String
            returnsData = query[kSecReturnData as String] as? Bool
        }
    }

    struct State {
        var items: [Item: Data] = [:]
        var calls: [Call] = []
        var readStatus: OSStatus?
    }

    let state = Mutex(State())
    private let updateStatus: OSStatus?
    private let addStatus: OSStatus?
    var calls: [Call] { state.withLock { $0.calls } }

    init(updateStatus: OSStatus? = nil, addStatus: OSStatus? = nil) {
        self.updateStatus = updateStatus
        self.addStatus = addStatus
    }

    func data(matching query: [String: Any]) -> (OSStatus, Data?) {
        let call = Call(.read, query: query)
        return state.withLock {
            $0.calls.append(call)
            if let status = $0.readStatus { return (status, nil) }
            guard call.returnsData == true else { return (errSecParam, nil) }
            guard let data = $0.items[call.item] else { return (errSecItemNotFound, nil) }
            return (errSecSuccess, data)
        }
    }

    func update(matching query: [String: Any], attributes: [String: Any]) -> OSStatus {
        let call = Call(.update, query: query, attributes: attributes)
        return state.withLock {
            $0.calls.append(call)
            if let updateStatus { return updateStatus }
            guard $0.items[call.item] != nil else { return errSecItemNotFound }
            guard let data = call.data else { return errSecParam }
            $0.items[call.item] = data
            return errSecSuccess
        }
    }

    func add(_ attributes: [String: Any]) -> OSStatus {
        let call = Call(.add, query: attributes, attributes: attributes)
        return state.withLock {
            $0.calls.append(call)
            if let addStatus { return addStatus }
            guard $0.items[call.item] == nil else { return errSecDuplicateItem }
            guard let data = call.data else { return errSecParam }
            $0.items[call.item] = data
            return errSecSuccess
        }
    }

    func delete(matching query: [String: Any]) {
        let call = Call(.delete, query: query)
        state.withLock {
            $0.calls.append(call)
            $0.items[call.item] = nil
        }
    }
}
