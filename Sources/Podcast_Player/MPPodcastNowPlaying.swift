import Foundation
import MediaPlayer
import RSS_Shared_Backend
#if canImport(UIKit)
import UIKit
#endif

/// Shows the loaded episode on the Lock Screen and in Control Center through MediaPlayer, and forwards their commands.
/// It holds the system controls only while it has something to show: `update(nil)` and `deinit` hand them back.
/// The host app needs the `audio` background mode for playback to go on once the screen locks.
@MainActor
public final class MPPodcastNowPlaying: PodcastNowPlaying {
    /// Receives play, pause, skip and scrub commands, on the main actor.
    public var onCommand: (@MainActor (PodcastRemoteCommand) -> Void)?

    private let skipBackInterval: TimeInterval
    private let skipForwardInterval: TimeInterval
    private var info: PodcastNowPlayingInfo?
    // Empty while nothing is shown. Only touched on the main actor, and by `deinit` once nothing else can reach this object.
    private nonisolated(unsafe) var targets: [(command: MPRemoteCommand, target: Any)] = []
    #if canImport(UIKit)
    private var artworkURL: URL?
    private var artwork: MPMediaItemArtwork?
    #endif

    /// - Parameters:
    ///   - skipBackInterval: Seconds the skip-back button rewinds.
    ///   - skipForwardInterval: Seconds the skip-forward button advances.
    public init(skipBackInterval: TimeInterval = 15, skipForwardInterval: TimeInterval = 30) {
        self.skipBackInterval = skipBackInterval
        self.skipForwardInterval = skipForwardInterval
    }

    deinit {
        guard !targets.isEmpty else { return }
        Self.release(targets)
    }

    /// Shows `info` and takes the system controls, or hands them back when nil.
    public func update(_ info: PodcastNowPlayingInfo?) {
        self.info = info
        guard let info else {
            guard !targets.isEmpty else { return }
            Self.release(targets)
            targets = []
            return
        }
        if targets.isEmpty { addTargets() }
        #if canImport(UIKit)
        loadArtwork(for: info.episode)
        #endif
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo(for: info)
    }

    private func nowPlayingInfo(for info: PodcastNowPlayingInfo) -> [String: Any] {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: info.episode.title,
            MPMediaItemPropertyArtist: info.episode.podcastTitle,
            MPMediaItemPropertyAlbumTitle: info.episode.podcastTitle,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: info.elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: info.isPlaying ? 1.0 : 0.0,
        ]
        if info.duration > 0 { nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = info.duration }
        #if canImport(UIKit)
        if let artwork, artworkURL == info.episode.artworkURL { nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork }
        #endif
        return nowPlayingInfo
    }

    private func addTargets() {
        let center = MPRemoteCommandCenter.shared()
        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: skipBackInterval)]
        center.skipForwardCommand.preferredIntervals = [NSNumber(value: skipForwardInterval)]
        add(center.playCommand) { _ in .play }
        add(center.pauseCommand) { _ in .pause }
        add(center.togglePlayPauseCommand) { _ in .togglePlayPause }
        add(center.skipBackwardCommand) { ($0 as? MPSkipIntervalCommandEvent).map { .skip(-$0.interval) } }
        add(center.skipForwardCommand) { ($0 as? MPSkipIntervalCommandEvent).map { .skip($0.interval) } }
        add(center.changePlaybackPositionCommand) {
            ($0 as? MPChangePlaybackPositionCommandEvent).map { .seek($0.positionTime) }
        }
    }

    /// Forwards `command`'s events to `onCommand` as whatever `remoteCommand` makes of them.
    private func add(
        _ command: MPRemoteCommand,
        _ remoteCommand: @escaping @Sendable (MPRemoteCommandEvent) -> PodcastRemoteCommand?
    ) {
        let target = command.addTarget { [weak self] event in
            MainActor.assumeIsolated {
                guard let remoteCommand = remoteCommand(event), let onCommand = self?.onCommand else { return .commandFailed }
                onCommand(remoteCommand)
                return .success
            }
        }
        targets.append((command, target))
    }

    /// Removes `targets` and clears what the system shows.
    private nonisolated static func release(_ targets: [(command: MPRemoteCommand, target: Any)]) {
        targets.forEach { $0.command.removeTarget($0.target) }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    #if canImport(UIKit)
    /// Downloads `episode`'s artwork once per URL, then adds it if that artwork is still the one showing.
    private func loadArtwork(for episode: PodcastEpisode) {
        guard let url = episode.artworkURL, url != artworkURL else { return }
        artworkURL = url
        artwork = nil
        Task { [weak self] in
            guard let data = try? await URLSession.shared.data(from: url).0,
                  let artwork = Self.makeArtwork(from: data),
                  let self, self.artworkURL == url else { return }
            self.artwork = artwork
            guard self.info?.episode.artworkURL == url else { return }
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
        }
    }

    /// Kept off the main actor: the system asks for the image on a queue of its own.
    private nonisolated static func makeArtwork(from data: Data) -> MPMediaItemArtwork? {
        guard let image = UIImage(data: data) else { return nil }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
    #endif
}
