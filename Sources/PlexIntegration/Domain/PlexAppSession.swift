import Foundation
import Plex_Shared_Backend
import PlexLauncher

/// The app's single Plex session, shared by Settings, matching and playback.
public enum PlexAppSession {
    public static let shared: any PlexLaunching = PlexSharedLauncher(PlexLauncher(
        identity: identity,
        credentials: PlexKeychainCredentialStore(service: "GlenMovies.Plex", account: "plex-session")
    ))

    /// Plex ties sign-in PINs and sessions to the client identifier, so it is generated once per installation.
    private static var identity: PlexClientIdentity {
        let defaults = UserDefaults.standard
        let identifier = defaults.string(forKey: "plex-client-id") ?? UUID().uuidString
        defaults.set(identifier, forKey: "plex-client-id")
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1"
        // A generated UUID and these fixed fields always satisfy header validation.
        guard let identity = try? PlexClientIdentity(identifier: identifier, product: "Glen Movies", version: version, platform: "iOS") else {
            preconditionFailure("Invalid Plex client identity")
        }
        return identity
    }
}
