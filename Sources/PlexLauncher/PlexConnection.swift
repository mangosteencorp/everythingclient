import Foundation
import Plex_Shared_Backend

/// A connected server and its initial library sections. Use `api` for Plex's full server API.
/// Keep this object only while the session is active: signing out cannot revoke copies held by your app.
public final class PlexConnection: Sendable {
    /// The server's display name.
    public let name: String
    /// The signed-in account's name, absent for manual server connections.
    public let accountName: String?
    /// The sections returned when this connection was verified.
    public let libraries: [PlexLibrary]
    /// The underlying, server-scoped API. Its configuration uses the server token.
    public let api: PlexAPIService

    /// Creates a connection, including for a `PlexLaunching` test double.
    public init(name: String, accountName: String? = nil, libraries: [PlexLibrary], api: PlexAPIService) {
        self.name = name
        self.accountName = accountName
        self.libraries = libraries
        self.api = api
    }
}

/// A pending browser sign-in. The app owns presentation, polling cadence and cancellation.
public struct PlexSignIn: Sendable {
    /// Pass this ID to `completeSignIn(pinID:)`.
    public let id: String
    /// The code to show beside the browser sign-in action.
    public let code: String
    /// The server's reported PIN lifetime, in seconds.
    public let expiresIn: Int?
    /// Open this URL in the app's browser presentation.
    public let authorizationURL: URL

    /// Creates a pending sign-in, including for a `PlexLaunching` test double.
    public init(id: String, code: String, expiresIn: Int?, authorizationURL: URL) {
        self.id = id
        self.code = code
        self.expiresIn = expiresIn
        self.authorizationURL = authorizationURL
    }
}

/// Session lifecycle errors. Network and Plex failures retain their backend error types.
public enum PlexLauncherError: Error, Equatable, Sendable {
    /// Sign in or resume an account session before discovering servers.
    case signInRequired
    /// Begin a sign-in before polling its PIN; cancelled or replaced PINs cannot finish a session.
    case signInNotPending
    /// A saved address now belongs to a different server.
    case serverIdentityMismatch
}
