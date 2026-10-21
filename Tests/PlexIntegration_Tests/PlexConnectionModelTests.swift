import Foundation
import Plex_Shared_Backend
import PlexIntegration
import PlexLauncher
import Testing

@MainActor
struct PlexConnectionModelTests {
    @Test func resumedSessionShowsTheServerAndAccount() async throws {
        let model = PlexConnectionModel(launcher: try LaunchingFake(resume: .success(connection())))
        await model.refresh()
        #expect(model.status == .connected(PlexConnectionInfo(serverName: "Home Cinema", accountName: "Alex")))
    }

    @Test func refreshShowsTheSharedConnectionWithoutResuming() async throws {
        let launcher = try LaunchingFake(best: connection(name: "Studio"))
        _ = try await launcher.connectBest()
        let model = PlexConnectionModel(launcher: launcher)
        await model.refresh()
        #expect(model.status == .connected(PlexConnectionInfo(serverName: "Studio", accountName: "Alex")))
        #expect(await launcher.resumeCount == 0)
    }

    @Test func noSavedSessionIsSignedOut() async {
        let model = PlexConnectionModel(launcher: LaunchingFake())
        await model.refresh()
        #expect(model.status == .signedOut)
    }

    @Test func resumeFailureKeepsSignOutAvailable() async {
        let launcher = LaunchingFake(hasAccount: true, resume: .failure(PlexAPIError.noReachableServer))
        let model = PlexConnectionModel(launcher: launcher)
        await model.refresh()
        #expect(model.status == .failed(message: L10n.plexErrorNoReachableServer, canSignOut: true))
    }

    @Test func signInPollsUntilApprovedThenConnectsTheBestServer() async throws {
        let launcher = try LaunchingFake(polls: [false, false, true], best: connection(name: "Studio"))
        let model = PlexConnectionModel(launcher: launcher, pollInterval: .milliseconds(1))
        var opened: [URL] = []
        await model.signIn { opened.append($0) }
        #expect(model.status == .connected(PlexConnectionInfo(serverName: "Studio", accountName: "Alex")))
        #expect(opened == [LaunchingFake.signIn.authorizationURL])
        #expect(await launcher.pollCount == 3)
        #expect(await launcher.connectBestCount == 1)
    }

    @Test func expiredCodeFails() async {
        let launcher = LaunchingFake(pollFailure: PlexAPIError.pinExpired)
        let model = PlexConnectionModel(launcher: launcher, pollInterval: .milliseconds(1))
        await model.signIn { _ in }
        #expect(model.status == .failed(message: L10n.plexErrorPinExpired, canSignOut: false))
        #expect(await launcher.connectBestCount == 0)
    }

    @Test func cancellingStopsPollingWithoutConnecting() async {
        let launcher = LaunchingFake()
        let model = PlexConnectionModel(launcher: launcher, pollInterval: .milliseconds(1))
        let signIn = Task { await model.signIn { _ in } }
        await launcher.waitUntilPolled()
        #expect(model.status == .signingIn(code: "ABCD", authorizationURL: LaunchingFake.signIn.authorizationURL))
        await model.cancelSignIn()
        await signIn.value
        #expect(model.status == .signedOut)
        #expect(await launcher.cancelCount == 1)
        #expect(await launcher.connectBestCount == 0)
    }

    @Test func refreshLeavesAPendingSignInRunning() async {
        let launcher = LaunchingFake()
        let model = PlexConnectionModel(launcher: launcher, pollInterval: .milliseconds(1))
        let signIn = Task { await model.signIn { _ in } }
        await launcher.waitUntilPolled()
        await model.refresh()
        #expect(model.status == .signingIn(code: "ABCD", authorizationURL: LaunchingFake.signIn.authorizationURL))
        #expect(await launcher.resumeCount == 0)
        await model.cancelSignIn()
        await signIn.value
    }

    @Test func signOutForgetsTheSession() async throws {
        let launcher = try LaunchingFake(hasAccount: true, resume: .success(connection()))
        let model = PlexConnectionModel(launcher: launcher)
        await model.refresh()
        await model.signOut()
        #expect(model.status == .signedOut)
        #expect(await launcher.signOutCount == 1)
    }
}

func connection(name: String = "Home Cinema", transport: any PlexHTTPTransport = PlexURLSessionTransport()) throws -> PlexConnection {
    let identity = try PlexClientIdentity(identifier: "tests", product: "Tests", version: "1", platform: "iOS")
    let configuration = try PlexServerConfiguration(baseURL: #require(URL(string: "https://plex.example")), token: "token", identity: identity)
    return PlexConnection(name: name, accountName: "Alex", libraries: [], api: PlexAPIService(configuration: configuration, transport: transport))
}

actor LaunchingFake: PlexLaunching {
    static let signIn = PlexSignIn(id: "pin", code: "ABCD", expiresIn: 300, authorizationURL: URL(string: "https://app.plex.tv/auth")!)

    private(set) var connection: PlexConnection?
    private(set) var hasAccount: Bool
    let accountName: String? = nil
    private let resumeResult: Result<PlexConnection?, any Error>
    private var polls: [Bool]
    private let pollFailure: (any Error)?
    private let best: PlexConnection?
    private var pollWaiters: [CheckedContinuation<Void, Never>] = []
    /// While true, `resume()` waits for `releaseResume()`.
    private var holdsResume: Bool
    private var resumeWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var resumeCount = 0
    private(set) var pollCount = 0
    private(set) var connectBestCount = 0
    private(set) var cancelCount = 0
    private(set) var signOutCount = 0

    /// `polls` are returned in order, then pending forever.
    init(
        hasAccount: Bool = false, resume: Result<PlexConnection?, any Error> = .success(nil), polls: [Bool] = [],
        pollFailure: (any Error)? = nil, best: PlexConnection? = nil, holdsResume: Bool = false
    ) {
        self.hasAccount = hasAccount
        self.holdsResume = holdsResume
        resumeResult = resume
        self.polls = polls
        self.pollFailure = pollFailure
        self.best = best
    }

    func waitUntilPolled() async {
        guard pollCount == 0 else { return }
        await withCheckedContinuation { pollWaiters.append($0) }
    }

    func beginSignIn() -> PlexSignIn { Self.signIn }

    func completeSignIn(pinID _: String) throws -> Bool {
        pollCount += 1
        pollWaiters.forEach { $0.resume() }
        pollWaiters = []
        if let pollFailure { throw pollFailure }
        guard !polls.isEmpty else { return false }
        let approved = polls.removeFirst()
        hasAccount = hasAccount || approved
        return approved
    }

    func cancelSignIn() { cancelCount += 1 }
    func servers() -> [PlexServerResource] { [] }
    func connect(to _: PlexServerResource, allowHTTP _: Bool) throws -> PlexConnection { throw PlexAPIError.noReachableServer }

    func connectBest(content _: PlexServerContent, allowHTTP _: Bool) throws -> PlexConnection {
        connectBestCount += 1
        guard let best else { throw PlexAPIError.noReachableServer }
        connection = best
        return best
    }

    func connect(baseURL _: URL, token _: String, name _: String?, allowHTTP _: Bool) throws -> PlexConnection {
        throw PlexAPIError.noReachableServer
    }

    func releaseResume() {
        holdsResume = false
        resumeWaiters.forEach { $0.resume() }
        resumeWaiters = []
    }

    func resume(allowHTTP _: Bool) async throws -> PlexConnection? {
        resumeCount += 1
        if holdsResume { await withCheckedContinuation { resumeWaiters.append($0) } }
        connection = try resumeResult.get()
        return connection
    }

    func signOut() {
        signOutCount += 1
        connection = nil
        hasAccount = false
    }
}
