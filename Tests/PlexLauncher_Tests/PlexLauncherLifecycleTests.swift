import Foundation
import Plex_Shared_Backend
import PlexLauncher
import Testing

struct PlexLauncherLifecycleTests {
    @Test func manualConnectionVerifiesBeforeSavingAndClearsPreviousAccountAssociation() async throws {
        let credentials = LauncherCredentialStore(PlexStoredSession(accountToken: "previous-account", accountName: "Previous"))
        let transport = LauncherTransport { request in
            request.url?.path == "/library/sections" ? launcherSections : launcherServerInfo
        }
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, transport: transport)
        let connection = try await launcher.connect(baseURL: #require(URL(string: "https://manual.example")), token: "manual-token")

        #expect(connection.name == "Home")
        #expect(connection.accountName == nil)
        #expect(connection.api.configuration.machineIdentifier == "saved-server")
        #expect(connection.libraries.map(\.key) == ["1"])
        #expect(credentials.load()?.accountToken == nil)
        #expect(credentials.load()?.server?.machineIdentifier == "saved-server")
        #expect(await transport.requests.allSatisfy { $0.value(forHTTPHeaderField: "X-Plex-Token") == "manual-token" })
    }

    @Test func manualHTTPRequiresExplicitOptInBeforeAnyNetworkOrPersistence() async throws {
        let credentials = LauncherCredentialStore()
        let transport = LauncherTransport { request in
            request.url?.path == "/library/sections" ? launcherSections : launcherServerInfo
        }
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, transport: transport)
        let baseURL = try #require(URL(string: "http://manual.example"))

        await #expect(throws: PlexAPIError.invalidConfiguration) { try await launcher.connect(baseURL: baseURL, token: "manual-token") }
        #expect(await transport.requests.isEmpty)
        #expect(credentials.load() == nil)
        _ = try await launcher.connect(baseURL: baseURL, token: "manual-token", allowHTTP: true)
        #expect(credentials.load()?.server?.baseURL == baseURL)
    }

    @Test func savedHTTPRequiresOptInAgain() async throws {
        let previous = PlexStoredSession(server: try launcherConfiguration(baseURL: "http://manual.example").credential(name: "Home"))
        let credentials = LauncherCredentialStore(previous)
        let transport = LauncherTransport { request in
            request.url?.path == "/library/sections" ? launcherSections : launcherServerInfo
        }
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, transport: transport)

        await #expect(throws: PlexAPIError.invalidConfiguration) { try await launcher.resume() }
        #expect(await transport.requests.isEmpty)
        #expect(credentials.load() == previous)
        #expect(try await launcher.resume(allowHTTP: true) != nil)
    }

    @Test func failedSecureSaveDoesNotPublishConnectionOrTriggerRediscovery() async throws {
        let previous = PlexStoredSession(accountToken: "account-token", server: try launcherConfiguration().credential(name: "Home"))
        let credentials = LauncherCredentialStore(previous, rejectsWrites: true)
        let account = try LauncherAccount(resources: [launcherResource()])
        let transport = LauncherTransport { request in
            request.url?.path == "/library/sections" ? launcherSections : launcherServerInfo
        }
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, transport: transport, account: account)

        await #expect(throws: LauncherCredentialStore.Failure.rejected) { try await launcher.resume() }
        #expect(await launcher.connection == nil)
        #expect(await account.discoveryTokens.isEmpty)
        #expect(credentials.load() == previous)
    }

    @Test func failedConnectionPreservesExistingConnectionAndStoredCredential() async throws {
        let credentials = LauncherCredentialStore()
        let connector = LauncherConnector()
        let transport = LauncherTransport()
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, transport: transport, connector: connector)
        let connected = try await launcher.connect(to: launcherResource())
        let previous = credentials.load()

        await #expect(throws: URLError.self) {
            try await launcher.connect(baseURL: #require(URL(string: "https://unreachable.example")), token: "manual-token")
        }
        #expect(await launcher.connection === connected)
        #expect(credentials.load() == previous)
    }

    @Test func signOutCannotBeUndoneByAnInFlightConnection() async throws {
        let gate = LauncherGate()
        let credentials = LauncherCredentialStore(PlexStoredSession(accountToken: "account-token"))
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, connector: LauncherConnector(gate: gate))
        let resource = try launcherResource()
        let task = Task { try await launcher.connect(to: resource) }
        await gate.waitUntilEntered()
        await launcher.signOut()
        await gate.open()

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(credentials.load() == nil)
        #expect(credentials.writes == 0)
        #expect(await launcher.connection == nil)
        #expect(await launcher.hasAccount == false)
    }

    @Test func signOutCannotBeUndoneByAnInFlightPINPoll() async throws {
        let gate = LauncherGate()
        let credentials = LauncherCredentialStore()
        let account = try LauncherAccount(pinTokens: ["authorized-token"], pinGate: gate)
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, account: account)
        let signIn = try await launcher.beginSignIn()
        let task = Task { try await launcher.completeSignIn(pinID: signIn.id) }
        await gate.waitUntilEntered()
        await launcher.signOut()
        await gate.open()

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(credentials.load() == nil)
        #expect(credentials.writes == 0)
        #expect(await launcher.hasAccount == false)
    }

    @Test func cancellationPreventsPersistenceEvenWhenAConnectorIgnoresIt() async throws {
        let gate = LauncherGate()
        let credentials = LauncherCredentialStore()
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, connector: LauncherConnector(gate: gate))
        let resource = try launcherResource()
        let task = Task { try await launcher.connect(to: resource) }
        await gate.waitUntilEntered()
        task.cancel()
        await gate.open()

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(credentials.load() == nil)
        #expect(await launcher.connection == nil)
    }

    @Test func aNewConnectionSupersedesAnOlderConnection() async throws {
        let gate = LauncherGate()
        let credentials = LauncherCredentialStore()
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, connector: LauncherConnector(gate: gate))
        let first = try launcherResource(id: "first", name: "First")
        let second = try launcherResource(id: "second", name: "Second")
        let oldTask = Task { try await launcher.connect(to: first) }
        await gate.waitUntilEntered()
        let newTask = Task { try await launcher.connect(to: second) }
        await gate.waitUntilEntered(2)
        await gate.open()

        let connection = try await newTask.value
        await #expect(throws: CancellationError.self) { try await oldTask.value }
        #expect(connection.name == "Second")
        #expect(credentials.load()?.server?.machineIdentifier == "second")
    }
}
