import Foundation
import Plex_Shared_Backend
import PlexLauncher
import Testing

struct PlexLauncherTests {
    @Test func noSavedSessionNeedsNoNetworkOrPIN() async throws {
        let transport = LauncherTransport()
        let account = try LauncherAccount()
        let launcher: any PlexLaunching = PlexLauncher(identity: try launcherIdentity(), credentials: LauncherCredentialStore(), transport: transport, account: account)

        #expect(try await launcher.resume() == nil)
        #expect(await launcher.hasAccount == false)
        #expect(await transport.requests.isEmpty)
        #expect(await account.createCount == 0)
        await #expect(throws: PlexLauncherError.signInRequired) { try await launcher.servers() }
    }

    @Test func pendingPINDoesNotReplaceExistingSessionUntilAuthorized() async throws {
        let previous = PlexStoredSession(accountToken: "previous-account", accountName: "Previous", server: try launcherConfiguration().credential(name: "Old"))
        let credentials = LauncherCredentialStore(previous)
        let account = try LauncherAccount(pinTokens: [nil, "new-account-token"])
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, account: account)
        let signIn = try await launcher.beginSignIn()

        #expect(signIn.code == "pin-code")
        #expect(signIn.authorizationURL.host() == "app.plex.tv")
        #expect(try await launcher.completeSignIn(pinID: signIn.id) == false)
        #expect(credentials.load() == previous)
        #expect(try await launcher.completeSignIn(pinID: signIn.id))
        #expect(credentials.load()?.accountToken == "new-account-token")
        #expect(credentials.load()?.accountName == "Alex")
        #expect(credentials.load()?.server == nil)
        #expect(await launcher.hasAccount)
        #expect(await launcher.connection == nil)
        await #expect(throws: PlexLauncherError.signInNotPending) { try await launcher.completeSignIn(pinID: signIn.id) }
    }

    @Test func cancelledSignInPreservesSavedAccount() async throws {
        let previous = PlexStoredSession(accountToken: "previous-account", accountName: "Previous")
        let credentials = LauncherCredentialStore(previous)
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, account: try LauncherAccount(pinTokens: ["new-account-token"]))
        let signIn = try await launcher.beginSignIn()
        await launcher.cancelSignIn()

        await #expect(throws: PlexLauncherError.signInNotPending) { try await launcher.completeSignIn(pinID: signIn.id) }
        #expect(credentials.load() == previous)
        #expect(await launcher.accountName == "Previous")
    }

    @Test func resumeVerifiesLiveIdentityAndUsesSavedServerTokenWithoutSigningIn() async throws {
        let credentials = LauncherCredentialStore(PlexStoredSession(accountToken: "account-token", accountName: "Alex", server: try launcherConfiguration().credential(name: "Old name")))
        let transport = LauncherTransport { request in
            request.url?.path == "/library/sections" ? launcherSections : launcherServerInfo
        }
        let account = try LauncherAccount()
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, transport: transport, account: account)
        let connection = try #require(await launcher.resume())

        #expect(connection.name == "Home")
        #expect(connection.accountName == "Alex")
        #expect(connection.libraries.map(\.key) == ["1"])
        let requests = await transport.requests
        #expect(requests.map { $0.url?.path } == ["/", "/library/sections"])
        #expect(requests.allSatisfy { $0.value(forHTTPHeaderField: "X-Plex-Token") == "saved-server-token" })
        #expect(requests.allSatisfy { $0.value(forHTTPHeaderField: "X-Plex-Client-Identifier") == "saved-client" })
        #expect(await account.createCount == 0)
        #expect(await account.discoveryTokens.isEmpty)
        #expect(credentials.load()?.server?.name == "Home")
        _ = try await connection.api.libraries()
        #expect(await transport.requests.count == 3)
    }

    @Test func staleSavedAddressRediscoversOnlyTheSameServerAndRefreshesItsToken() async throws {
        let credentials = LauncherCredentialStore(PlexStoredSession(accountToken: "account-token", accountName: "Alex", server: try launcherConfiguration().credential(name: "Old")))
        let account = try LauncherAccount(resources: [launcherResource(id: "unrelated", name: "Other"), launcherResource()])
        let connector = LauncherConnector()
        let transport = LauncherTransport { request in
            guard request.url?.host() == "fresh.example" else { throw URLError(.cannotConnectToHost) }
            return launcherSections
        }
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, transport: transport, account: account, connector: connector)
        let connection = try #require(await launcher.resume())

        #expect(await connector.connectedIDs == ["saved-server"])
        #expect(await account.discoveryTokens == ["account-token"])
        #expect(connection.api.configuration.baseURL.host() == "fresh.example")
        #expect(credentials.load()?.server?.baseURL.host() == "fresh.example")
        #expect(credentials.load()?.accountName == "Alex")
        _ = try await connection.api.libraries()
        #expect(await transport.requests.last?.value(forHTTPHeaderField: "X-Plex-Token") == "fresh-server-token")
    }

    @Test func resumeRejectsWrongServerWithoutLosingStoredCredentials() async throws {
        let previous = PlexStoredSession(server: try launcherConfiguration().credential(name: "Home"))
        let credentials = LauncherCredentialStore(previous)
        let transport = LauncherTransport { _ in #"{"MediaContainer":{"machineIdentifier":"different-server"}}"# }
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, transport: transport)

        await #expect(throws: PlexLauncherError.serverIdentityMismatch) { try await launcher.resume() }
        #expect(credentials.load() == previous)
        #expect(credentials.writes == 0)
        #expect(await launcher.connection == nil)
        #expect(await transport.requests.count == 1)
    }

    @Test func missingSavedServerNeverSwitchesToAnotherResource() async throws {
        let previous = PlexStoredSession(accountToken: "account-token", server: try launcherConfiguration().credential(name: "Home"))
        let credentials = LauncherCredentialStore(previous)
        let connector = LauncherConnector()
        let launcher = PlexLauncher(
            identity: try launcherIdentity(), credentials: credentials, transport: LauncherTransport(),
            account: try LauncherAccount(resources: [launcherResource(id: "unrelated")]), connector: connector
        )

        await #expect(throws: PlexAPIError.noReachableServer) { try await launcher.resume() }
        #expect(credentials.load() == previous)
        #expect(await connector.connectedIDs.isEmpty)
    }

    @Test func accountSavedBeforeChoosingAServerResumesUsingAutomaticSelection() async throws {
        let credentials = LauncherCredentialStore(PlexStoredSession(accountToken: "account-token", accountName: "Alex"))
        let account = try LauncherAccount(resources: [launcherResource()])
        let connector = LauncherConnector()
        let launcher = PlexLauncher(identity: try launcherIdentity(), credentials: credentials, account: account, connector: connector)
        let connection = try #require(await launcher.resume())

        #expect(connection.name == "Home")
        #expect(connection.accountName == "Alex")
        #expect(await connector.contentChoices.map(\.rawValue) == [PlexServerContent([.movies, .shows]).rawValue])
        #expect(credentials.load()?.server?.machineIdentifier == "saved-server")
    }

    @Test func explicitContentAndHTTPChoiceReachTheConnector() async throws {
        let connector = LauncherConnector()
        let launcher = PlexLauncher(
            identity: try launcherIdentity(), credentials: LauncherCredentialStore(PlexStoredSession(accountToken: "account-token")),
            account: try LauncherAccount(resources: [launcherResource()]), connector: connector
        )
        _ = try await launcher.connectBest(content: .shows, allowHTTP: true)

        #expect(await connector.contentChoices.map(\.rawValue) == [PlexServerContent.shows.rawValue])
        #expect(await connector.httpChoices == [true])
    }
}
