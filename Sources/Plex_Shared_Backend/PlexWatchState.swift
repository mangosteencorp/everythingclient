import Foundation

/// The player state reported with `reportTimeline`.
public enum PlexPlaybackState: String, Codable, Sendable {
    /// Report `playing`/`paused` periodically during playback and `stopped` when it ends; `stopped` saves the resume point.
    case playing, paused, stopped, buffering
}

/// Watched flags, resume positions, ratings and Continue Watching membership.
public protocol PlexWatchStateServing: Sendable {
    /// Marks an item, or every episode of a show or season, as watched.
    func markWatched(ratingKey: String) async throws
    /// Marks an item, or every episode of a show or season, as unwatched.
    func markUnwatched(ratingKey: String) async throws
    /// Reports a playback position in milliseconds. `recordedAt` marks a replay of offline progress.
    func reportTimeline(
        ratingKey: String, state: PlexPlaybackState, time: Int64, duration: Int64?, recordedAt: Date?
    ) async throws
    /// A 0–10 user rating; nil clears it.
    func rate(ratingKey: String, rating: Double?) async throws
    /// Hides an item from Continue Watching without changing its watched state or progress.
    func removeFromContinueWatching(ratingKey: String) async throws
    /// The server's "watched" percentage (`LibraryVideoPlayedThreshold`), 90 by default.
    func watchedThreshold() async throws -> Double
}

extension PlexAPIService: PlexWatchStateServing {
    private static let libraryIdentifier = URLQueryItem(name: "identifier", value: "com.plexapp.plugins.library")

    /// `GET /:/scrobble?key={id}&identifier=com.plexapp.plugins.library`.
    public func markWatched(ratingKey: String) async throws {
        try await send(PlexEndpoint(.get, "/:/scrobble", query: [URLQueryItem(name: "key", value: ratingKey), Self.libraryIdentifier]))
    }

    /// `GET /:/unscrobble?key={id}&identifier=com.plexapp.plugins.library`.
    public func markUnwatched(ratingKey: String) async throws {
        try await send(PlexEndpoint(.get, "/:/unscrobble", query: [URLQueryItem(name: "key", value: ratingKey), Self.libraryIdentifier]))
    }

    /// `POST /:/timeline` with `state`, `time` and `duration`. A `recordedAt` date adds `offline=1&updated={seconds}`
    /// so the server applies a replayed offline position at the time it happened.
    public func reportTimeline(
        ratingKey: String, state: PlexPlaybackState, time: Int64, duration: Int64? = nil, recordedAt: Date? = nil
    ) async throws {
        let query: [URLQueryItem?] = [
            URLQueryItem(name: "ratingKey", value: ratingKey),
            URLQueryItem(name: "key", value: "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))"),
            URLQueryItem(name: "state", value: state.rawValue),
            URLQueryItem(name: "time", value: String(max(time, 0))),
            duration.map { URLQueryItem(name: "duration", value: String($0)) },
            recordedAt.map { _ in URLQueryItem(name: "offline", value: "1") },
            recordedAt.map { URLQueryItem(name: "updated", value: String(Int64($0.timeIntervalSince1970))) },
        ]
        try await send(PlexEndpoint(.post, "/:/timeline", query: query.compactMap { $0 }))
    }

    /// `PUT /:/rate`. Ratings are clamped to 0–10; nil sends `-1`, which clears the rating.
    public func rate(ratingKey: String, rating: Double?) async throws {
        let value = rating.map { String(min(max($0, 0), 10)) } ?? "-1"
        try await send(PlexEndpoint(.put, "/:/rate", query: [
            URLQueryItem(name: "key", value: ratingKey), Self.libraryIdentifier, URLQueryItem(name: "rating", value: value),
        ]))
    }

    /// `PUT /actions/removeFromContinueWatching?ratingKey={id}`.
    public func removeFromContinueWatching(ratingKey: String) async throws {
        try await send(PlexEndpoint(.put, "/actions/removeFromContinueWatching", query: [URLQueryItem(name: "ratingKey", value: ratingKey)]))
    }

    /// Reads `LibraryVideoPlayedThreshold` from `GET /:/prefs` as a fraction, defaulting to 0.9.
    public func watchedThreshold() async throws -> Double {
        let settings = try await serverPreferences()
        return settings.first { $0.id == "LibraryVideoPlayedThreshold" }?.value.flatMap(Double.init).map { $0 / 100 } ?? 0.9
    }
}
