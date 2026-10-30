import Foundation
import Plex_Shared_Backend
import PlexLauncher

/// `PlexLauncher` cancels an older operation when a newer one starts. Settings and movie pages restore the same
/// session independently, so concurrent `resume()` calls share one request instead of cancelling each other.
actor PlexSharedLauncher: PlexLaunching {
    private let base: any PlexLaunching
    private var resuming: Task<PlexConnection?, any Error>?

    init(_ base: any PlexLaunching) {
        self.base = base
    }

    var connection: PlexConnection? { get async { await base.connection } }
    var hasAccount: Bool { get async { await base.hasAccount } }
    var accountName: String? { get async { await base.accountName } }

    func resume(allowHTTP: Bool) async throws -> PlexConnection? {
        if let resuming { return try await resuming.value }
        let task = Task { try await base.resume(allowHTTP: allowHTTP) }
        resuming = task
        defer { resuming = nil }
        return try await task.value
    }

    func beginSignIn() async throws -> PlexSignIn { try await base.beginSignIn() }
    func completeSignIn(pinID: String) async throws -> Bool { try await base.completeSignIn(pinID: pinID) }
    func cancelSignIn() async { await base.cancelSignIn() }
    func servers() async throws -> [PlexServerResource] { try await base.servers() }
    func signOut() async { await base.signOut() }

    func connect(to server: PlexServerResource, allowHTTP: Bool) async throws -> PlexConnection {
        try await base.connect(to: server, allowHTTP: allowHTTP)
    }

    func connectBest(content: PlexServerContent, allowHTTP: Bool) async throws -> PlexConnection {
        try await base.connectBest(content: content, allowHTTP: allowHTTP)
    }

    func connect(baseURL: URL, token: String, name: String?, allowHTTP: Bool) async throws -> PlexConnection {
        try await base.connect(baseURL: baseURL, token: token, name: name, allowHTTP: allowHTTP)
    }
}
