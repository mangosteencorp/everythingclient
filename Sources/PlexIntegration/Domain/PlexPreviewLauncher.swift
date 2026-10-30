#if DEBUG
import Foundation
import Plex_Shared_Backend
import PlexLauncher

/// A `PlexLaunching` for previews: no network, Keychain or browser.
public struct PlexPreviewLauncher: PlexLaunching {
    public enum Session: Sendable {
        case signedOut
        /// Restoring never finishes.
        case loading
        case connected
        /// An account is saved but its server is unreachable.
        case unreachable
        /// Sign-in fails because the code expired.
        case expiredSignIn
    }

    private let session: Session

    public init(_ session: Session = .connected) {
        self.session = session
    }

    public var connection: PlexConnection? {
        get async { session == .connected ? try? Self.sampleConnection() : nil }
    }

    public var hasAccount: Bool {
        get async { [.connected, .unreachable].contains(session) }
    }

    public var accountName: String? {
        get async { await hasAccount ? "Alex" : nil }
    }

    public func beginSignIn() async throws -> PlexSignIn {
        try PlexSignIn(id: "preview", code: "4K7Q", expiresIn: 900, authorizationURL: Self.url("https://plex.invalid/auth"))
    }

    public func completeSignIn(pinID _: String) async throws -> Bool {
        guard session != .expiredSignIn else { throw PlexAPIError.pinExpired }
        return false
    }

    public func cancelSignIn() async {}
    public func servers() async throws -> [PlexServerResource] { [] }

    public func connect(to _: PlexServerResource, allowHTTP _: Bool) async throws -> PlexConnection {
        try Self.sampleConnection()
    }

    public func connectBest(content _: PlexServerContent, allowHTTP _: Bool) async throws -> PlexConnection {
        try Self.sampleConnection()
    }

    public func connect(baseURL _: URL, token _: String, name _: String?, allowHTTP _: Bool) async throws -> PlexConnection {
        try Self.sampleConnection()
    }

    public func resume(allowHTTP _: Bool) async throws -> PlexConnection? {
        switch session {
        case .signedOut, .expiredSignIn:
            return nil
        case .loading:
            try await Task.sleep(for: .seconds(3600))
            return nil
        case .connected:
            return try Self.sampleConnection()
        case .unreachable:
            throw PlexAPIError.noReachableServer
        }
    }

    public func signOut() async {}

    private static func sampleConnection() throws -> PlexConnection {
        let identity = try PlexClientIdentity(identifier: "preview", product: "Preview", version: "1", platform: "iOS")
        let configuration = try PlexServerConfiguration(baseURL: url("https://plex.invalid"), token: "preview", identity: identity)
        return PlexConnection(name: "Home Cinema", accountName: "Alex", libraries: [], api: PlexAPIService(configuration: configuration))
    }

    private static func url(_ string: String) throws -> URL {
        guard let url = URL(string: string) else { throw PlexAPIError.invalidConfiguration }
        return url
    }
}
#endif
