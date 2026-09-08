import Foundation
#if canImport(SwiftfinLib)
import JellyfinAPI
import SwiftfinLib
#endif

/// One movie in the connected Jellyfin library, flattened off JellyfinAPI's `BaseItemDto` so the
/// feature modules that display it never have to link the SDK.
public struct JellyfinMovieMatch: Identifiable, Sendable, Equatable {
    public let id: String
    /// The library's own title, which is what a follow-up search has to be given to find it again.
    public let title: String
    /// Total runtime, when the server reports one.
    public let runtimeSeconds: Double?
    /// How much of the movie this user has watched, `0...1`. Zero when never started.
    public let playedFraction: Double
    /// Where playback resumes, in seconds. Zero when never started.
    public let resumeSeconds: Double
    public let isPlayed: Bool

    public init(
        id: String,
        title: String,
        runtimeSeconds: Double?,
        playedFraction: Double,
        resumeSeconds: Double,
        isPlayed: Bool
    ) {
        self.id = id
        self.title = title
        self.runtimeSeconds = runtimeSeconds
        self.playedFraction = playedFraction
        self.resumeSeconds = resumeSeconds
        self.isPlayed = isPlayed
    }
}

public enum JellyfinLibraryError: Error, LocalizedError, Equatable {
    /// Swiftfin is installed but nobody is signed in to a server.
    case notConnected

    public var errorDescription: String? {
        switch self {
        case .notConnected: "No Jellyfin server is connected."
        }
    }
}

/// The seam between a feature module and Swiftfin's signed-in Jellyfin session.
public protocol JellyfinLibraryServicing: Sendable {
    /// `false` when SwiftfinLib was dropped from this build (see `hasSwiftfin` in Package.swift).
    var isAvailable: Bool { get }

    /// The library movie for `title`, or `nil` when the library has nothing for it.
    ///
    /// The server is searched by title rather than by TMDB id: Jellyfin cannot filter on a provider
    /// id, so an id lookup means paging the entire movie library, while a title search is one
    /// request. `tmdbID` is then only used to *reject* a same-title-different-movie hit.
    ///
    /// - Throws: `JellyfinLibraryError.notConnected` when no user session exists.
    func findMovie(title: String, tmdbID: Int) async throws -> JellyfinMovieMatch?
}

/// Reads the library through Swiftfin, which owns the server URL and access token.
///
/// Talking to `JellyfinClient` directly would be leaner, but SwiftfinLib keeps its `UserSession`
/// (and therefore the configured client) internal, so the session-backed lookup it does expose is
/// the only way in without forking Swiftfin.
public struct SwiftfinJellyfinLibraryService: JellyfinLibraryServicing {
    public init() {}

    public var isAvailable: Bool {
        #if canImport(SwiftfinLib)
        true
        #else
        false
        #endif
    }

    public func findMovie(title: String, tmdbID: Int) async throws -> JellyfinMovieMatch? {
        #if canImport(SwiftfinLib)
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        SwiftfinRuntime.configureIfNeeded()

        do {
            guard let item = try await SwiftfinLibrary.firstMovie(matching: .keyword(title)),
                  item.matchesTMDBID(tmdbID) else { return nil }
            return JellyfinMovieMatch(item)
        } catch SwiftfinMoviePlaybackError.noCurrentUserSession {
            throw JellyfinLibraryError.notConnected
        }
        #else
        return nil
        #endif
    }
}

#if canImport(SwiftfinLib)

/// 100ns units, the unit every duration on the Jellyfin API is expressed in.
private let ticksPerSecond = 10_000_000.0

private extension JellyfinMovieMatch {
    init?(_ item: BaseItemDto) {
        guard let id = item.id else { return nil }
        let runtimeSeconds = item.runTimeTicks.map { Double($0) / ticksPerSecond }
        let resumeSeconds = Double(item.userData?.playbackPositionTicks ?? 0) / ticksPerSecond
        // `playedPercentage` is absent until playback starts, and is 0...100 rather than 0...1.
        let playedFraction = (item.userData?.playedPercentage ?? 0) / 100

        self.init(
            id: id,
            title: item.name ?? "",
            runtimeSeconds: runtimeSeconds,
            playedFraction: min(max(playedFraction, 0), 1),
            resumeSeconds: resumeSeconds,
            isPlayed: item.userData?.isPlayed ?? false
        )
    }
}

private extension BaseItemDto {
    /// A hit is accepted unless the server states a *different* TMDB id: libraries with unmatched
    /// items report no provider ids at all, and rejecting those would hide movies that are there.
    func matchesTMDBID(_ tmdbID: Int) -> Bool {
        guard let providerID = providerIDs?.first(where: { key, _ in
            ["themoviedb", "tmdb"].contains(key.lowercased().filter(\.isLetter))
        })?.value else { return true }

        return providerID == String(tmdbID)
    }
}
#endif
