import Foundation
import Plex_Shared_Backend
import PlexLauncher

/// One movie in the connected Plex library, flattened off `PlexMetadata` for the feature modules that display it.
public struct PlexMovieMatch: Identifiable, Sendable, Equatable {
    /// The item's rating key on its server.
    public let id: String
    public let title: String
    /// Total runtime, when the server reports one.
    public let runtimeSeconds: Double?
    /// How much of the movie this user has watched, `0...1`. Zero when never started.
    public let playedFraction: Double
    /// Where playback resumes, in seconds. Zero when never started.
    public let resumeSeconds: Double
    public let isPlayed: Bool
    /// The server that matched, so playback asks it, and not a server picked later in Settings, for this rating key.
    /// Only a match built outside this module (a preview or a test double) has none, and cannot play.
    let api: PlexAPIService?

    public init(id: String, title: String, runtimeSeconds: Double?, playedFraction: Double, resumeSeconds: Double, isPlayed: Bool) {
        self.id = id
        self.title = title
        self.runtimeSeconds = runtimeSeconds
        self.playedFraction = playedFraction
        self.resumeSeconds = resumeSeconds
        self.isPlayed = isPlayed
        api = nil
    }

    init(_ item: PlexMetadata, api: PlexAPIService) {
        id = item.ratingKey
        title = item.title
        runtimeSeconds = item.duration.map { Double($0) / 1000 }
        playedFraction = item.progress ?? 0
        resumeSeconds = Double(item.viewOffset ?? 0) / 1000
        isPlayed = item.isWatched
        self.api = api
    }

    /// The displayed values; the server handle is not part of a match's identity.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.id, lhs.title, lhs.runtimeSeconds, lhs.playedFraction, lhs.resumeSeconds, lhs.isPlayed)
            == (rhs.id, rhs.title, rhs.runtimeSeconds, rhs.playedFraction, rhs.resumeSeconds, rhs.isPlayed)
    }
}

public enum PlexLibraryError: Error, LocalizedError, Equatable {
    /// Nobody is signed in to Plex.
    case notConnected
    /// The server could not be reached or searched; the message is ready to show.
    case failed(String)

    public var errorDescription: String? {
        switch self {
        case .notConnected: L10n.plexLibraryNotConnected
        case let .failed(message): message
        }
    }
}

/// The seam between a feature module and the app's signed-in Plex session.
public protocol PlexLibraryServicing: Sendable {
    /// Whether a Plex session is saved, without touching the network, so callers can stay hidden for signed-out users.
    var isSignedIn: Bool { get async }

    /// The library movie for `title`, or `nil` when the library has nothing for it.
    ///
    /// Plex search hits carry only Plex's own `plex://` guid (this backend doesn't request or decode the `Guid` list
    /// that holds TMDB ids), so a hit is matched on being a movie with the same normalized title and, when both sides
    /// know one, a release year at most one apart.
    ///
    /// - Throws: `PlexLibraryError.notConnected` when no session exists, `.failed` when the server can't be searched.
    func findMovie(title: String, year: Int?) async throws -> PlexMovieMatch?
}

/// Searches the library of the app's shared Plex session.
public struct PlexLibraryService: PlexLibraryServicing {
    private let launcher: any PlexLaunching

    public init(launcher: any PlexLaunching = PlexAppSession.shared) {
        self.launcher = launcher
    }

    public var isSignedIn: Bool {
        get async {
            if await launcher.connection != nil { return true }
            return await launcher.hasAccount
        }
    }

    public func findMovie(title: String, year: Int?) async throws -> PlexMovieMatch? {
        let key = title.matchKey
        guard !key.isEmpty else { return nil }
        do {
            let api = try await connection().api
            let hits = try await api.search(query: title.trimmingCharacters(in: .whitespacesAndNewlines)).metadata
            return hits
                .first { $0.type == "movie" && $0.title.matchKey == key && Self.isSameYear($0.year, year) }
                .map { PlexMovieMatch($0, api: api) }
        } catch where !(error is PlexLibraryError || Task.isCancelled) {
            // Includes a launcher operation superseded by Settings, which surfaces as `CancellationError`.
            throw PlexLibraryError.failed(PlexConnectionModel.message(for: error))
        }
    }

    /// The live connection, restoring the saved one first. Settings only signs in with an account, so without one
    /// there is nothing to restore, and skipping `resume()` keeps a lookup from superseding a sign-in in progress.
    private func connection() async throws -> PlexConnection {
        if let connection = await launcher.connection { return connection }
        guard await launcher.hasAccount, let connection = try await launcher.resume() else { throw PlexLibraryError.notConnected }
        return connection
    }

    /// TMDB dates a movie by its first release, often a festival premiere, while a library may file it under the
    /// wide release, so a year apart is still the same movie.
    private static func isSameYear(_ lhs: Int?, _ rhs: Int?) -> Bool {
        guard let lhs, let rhs else { return true }
        return abs(lhs - rhs) <= 1
    }
}

private extension String {
    /// Case, accents and punctuation differ between TMDB and library titles ("Amélie", "Spider-Man: No Way Home").
    var matchKey: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).filter { $0.isLetter || $0.isNumber }
    }
}
