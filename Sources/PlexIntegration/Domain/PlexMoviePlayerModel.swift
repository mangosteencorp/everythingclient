import AVFoundation
import Foundation
import Observation
import Plex_Shared_Backend

/// Wraps AVFoundation so playback can be faked in tests.
@MainActor
protocol PlexPlayerCreating {
    func player(for request: URLRequest) -> AVPlayer
}

struct PlexAVPlayerFactory: PlexPlayerCreating {
    /// AVFoundation has no public way to send request headers, and newer runtimes ignore the private
    /// `AVURLAssetHTTPHeaderFieldsKey` (Plex then answers 403), so the credentials go in the player's URL instead.
    func player(for request: URLRequest) -> AVPlayer {
        Self.playbackURL(for: request).map { AVPlayer(url: $0) } ?? AVPlayer()
    }

    /// The request's URL with its `X-Plex-Token` header appended as a query parameter, which Plex also accepts.
    /// Only the token: with the other `X-Plex-*` headers in the query, Plex answers later range requests with 404.
    /// The result carries the token: hand it to the player only, never to logs or caches.
    nonisolated static func playbackURL(for request: URLRequest) -> URL? {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        guard let url = request.url,
              let token = request.value(forHTTPHeaderField: "X-Plex-Token")?.addingPercentEncoding(withAllowedCharacters: allowed),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return request.url }
        components.percentEncodedQuery = [components.percentEncodedQuery, "X-Plex-Token=\(token)"].compactMap { $0 }.joined(separator: "&")
        return components.url
    }
}

/// Plays one library movie: direct play when AVFoundation can open the original file, an HLS transcode otherwise.
/// Resumes where the server says the user stopped, reports `/:/timeline` progress every 10 seconds and on stop, and
/// ends its transcode session on stop.
@MainActor
@Observable
final class PlexMoviePlayerModel {
    private(set) var player: AVPlayer?
    private(set) var error: String?
    @ObservationIgnored private let match: PlexMovieMatch
    @ObservationIgnored private let factory: any PlexPlayerCreating
    @ObservationIgnored private var observer: Any?
    @ObservationIgnored private var duration: Int64?
    @ObservationIgnored private var transcodeSession: String?

    init(match: PlexMovieMatch, factory: any PlexPlayerCreating = PlexAVPlayerFactory()) {
        self.match = match
        self.factory = factory
    }

    static func canDirectPlay(_ version: PlexMediaVersion) -> Bool {
        ["mp4", "m4v", "mov"].contains(version.container?.lowercased() ?? "")
            && ["h264", "hevc", nil].contains(version.videoCodec?.lowercased())
    }

    func start() async {
        guard let api = match.api else {
            error = PlexLibraryError.notConnected.errorDescription
            return
        }
        do {
            // Search hits carry no media versions, and the resume point may have moved since the match was found.
            let item = try await api.metadata(ratingKey: match.id)
            guard let version = item.media.first, let part = version.parts.first else { throw PlexAPIError.noDownloadableMedia }
            let request: URLRequest
            if Self.canDirectPlay(version) {
                request = try api.directPlayRequest(part: part)
            } else {
                let session = UUID().uuidString
                request = try api.streamRequest(PlexStreamOptions(ratingKey: item.ratingKey, session: session))
                transcodeSession = session
            }
            try Task.checkCancellation()

            let player = factory.player(for: request)
            self.player = player
            duration = item.duration
            if let offset = item.viewOffset, (item.progress ?? 0) < 0.95 {
                await player.seek(to: CMTime(value: offset, timescale: 1000))
            }
            // Closed while seeking.
            guard self.player === player else { return }
            observer = player.addPeriodicTimeObserver(forInterval: CMTime(value: 10, timescale: 1), queue: .main) { [weak self] time in
                MainActor.assumeIsolated { self?.report(time) }
            }
            player.play()
        } catch {
            guard !Task.isCancelled else { return }
            self.error = error is URLError ? error.localizedDescription : L10n.plexPlaybackFailed
        }
    }

    /// Stops playback, saves the resume point and frees the transcoder. Does nothing once stopped. The returned task
    /// finishes when the server has been told.
    @discardableResult
    func stop() -> Task<Void, Never>? {
        guard let player, let api = match.api else { return nil }
        player.pause()
        if let observer { player.removeTimeObserver(observer) }
        observer = nil
        self.player = nil
        let ratingKey = match.id, time = player.currentTime().milliseconds, duration = duration, session = transcodeSession
        transcodeSession = nil
        return Task {
            try? await api.reportTimeline(ratingKey: ratingKey, state: .stopped, time: time, duration: duration)
            if let session { try? await api.stopStream(session: session) }
        }
    }

    /// AVFoundation also calls this when playback starts, pauses or seeks, which keeps the server's state current.
    private func report(_ time: CMTime) {
        guard let api = match.api, let player else { return }
        let ratingKey = match.id, duration = duration
        let state: PlexPlaybackState = player.timeControlStatus == .paused ? .paused : .playing
        Task { try? await api.reportTimeline(ratingKey: ratingKey, state: state, time: time.milliseconds, duration: duration) }
    }
}

private extension CMTime {
    var milliseconds: Int64 {
        isNumeric ? Int64(seconds * 1000) : 0
    }
}
