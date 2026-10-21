import Foundation
import Observation
import Plex_Shared_Backend
import PlexLauncher

/// Display information only; the session itself stays in `PlexLaunching`.
public struct PlexConnectionInfo: Equatable, Sendable {
    public let serverName: String
    /// Absent for manual server connections.
    public let accountName: String?

    public init(serverName: String, accountName: String?) {
        self.serverName = serverName
        self.accountName = accountName
    }
}

public enum PlexConnectionStatus: Equatable, Sendable {
    case loading
    case signedOut
    /// Waiting for the user to approve `code` at `authorizationURL`.
    case signingIn(code: String, authorizationURL: URL)
    case connected(PlexConnectionInfo)
    /// `canSignOut` is true while an account is saved.
    case failed(message: String, canSignOut: Bool)
}

/// Drives Plex sign-in for the UI. Each operation supersedes the previous one.
@MainActor
@Observable
public final class PlexConnectionModel {
    public private(set) var status: PlexConnectionStatus = .loading
    private let launcher: any PlexLaunching
    private let pollInterval: Duration
    @ObservationIgnored private var operation: Task<Void, Never>?

    public init(launcher: any PlexLaunching = PlexAppSession.shared, pollInterval: Duration = .seconds(2)) {
        self.launcher = launcher
        self.pollInterval = pollInterval
    }

    /// Shows the shared connection, restoring the saved session when there is none yet. A pending browser sign-in
    /// is left running.
    public func refresh() async {
        if case .signingIn = status { return }
        await perform {
            if let connection = await self.launcher.connection { return try self.update(Self.connected(connection)) }
            try self.update(.loading)
            let connection = try await self.launcher.resume()
            try self.update(connection.map(Self.connected) ?? .signedOut)
        }
    }

    /// Opens Plex's browser sign-in, polls until it is approved, then connects the best server.
    public func signIn(open: @escaping @MainActor (URL) -> Void) async {
        await perform {
            try self.update(.loading)
            let signIn = try await self.launcher.beginSignIn()
            try self.update(.signingIn(code: signIn.code, authorizationURL: signIn.authorizationURL))
            open(signIn.authorizationURL)
            repeat {
                try await Task.sleep(for: self.pollInterval)
            } while try await !self.launcher.completeSignIn(pinID: signIn.id)
            try self.update(.loading)
            try await self.update(Self.connected(self.launcher.connectBest()))
        }
    }

    /// Stops waiting for the browser; an existing connection stays.
    public func cancelSignIn() async {
        await perform {
            await self.launcher.cancelSignIn()
            try await self.update(self.launcher.connection.map(Self.connected) ?? .signedOut)
        }
    }

    public func signOut() async {
        await perform {
            await self.launcher.signOut()
            try self.update(.signedOut)
        }
    }

    private func perform(_ work: @escaping @MainActor () async throws -> Void) async {
        operation?.cancel()
        let task = Task {
            do {
                try await work()
            } catch where !(error is CancellationError) {
                let canSignOut = await launcher.hasAccount
                // A cancelled request can surface as URLError, which `update` ignores for a cancelled task.
                try? update(.failed(message: Self.message(for: error), canSignOut: canSignOut))
            } catch {}
        }
        operation = task
        await task.value
    }

    private func update(_ status: PlexConnectionStatus) throws {
        try Task.checkCancellation()
        self.status = status
    }

    private static func connected(_ connection: PlexConnection) -> PlexConnectionStatus {
        .connected(PlexConnectionInfo(serverName: connection.name, accountName: connection.accountName))
    }

    private static func message(for error: any Error) -> String {
        switch error {
        case PlexAPIError.pinExpired: L10n.plexErrorPinExpired
        case PlexAPIError.noReachableServer: L10n.plexErrorNoReachableServer
        case PlexAPIError.noServerWithContent: L10n.plexErrorNoServerWithContent
        case let error as URLError: error.localizedDescription
        default: L10n.plexErrorGeneric
        }
    }
}
