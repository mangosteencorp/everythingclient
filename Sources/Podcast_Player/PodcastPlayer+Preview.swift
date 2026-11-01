#if DEBUG
import Foundation
import RSS_Shared_Backend

/// An engine that never makes a sound: it accepts every command and reports nothing on its own.
@MainActor
public final class PodcastSilentAudioEngine: PodcastAudioEngine {
    /// Set by the player; previews call it to fake events.
    public var onEvent: (@MainActor (PodcastAudioEvent) -> Void)?

    /// Creates a silent engine.
    public init() {}

    /// Does nothing.
    public func load(_: URL) {}
    /// Does nothing.
    public func play() {}
    /// Does nothing.
    public func pause() {}
    /// Does nothing.
    public func seek(to _: TimeInterval) {}
    /// Does nothing.
    public func stop() {}
}

public extension PodcastPlayer {
    /// A silent player already in `state` with `episode`, `elapsed` seconds in, for previews in any module.
    static func preview(
        _ state: PodcastPlaybackState = .idle,
        episode: PodcastEpisode = .preview,
        elapsed: TimeInterval = 0
    ) -> PodcastPlayer {
        let engine = PodcastSilentAudioEngine()
        let player = PodcastPlayer(engine: engine)
        guard state != .idle else { return player }
        player.play(episode)
        switch state {
        case .playing, .paused:
            engine.onEvent?(.ready(duration: nil))
            engine.onEvent?(.time(elapsed))
            if state == .paused { player.pause() }
        case let .failed(message):
            engine.onEvent?(.failed(message))
        case .idle, .loading:
            break
        }
        return player
    }
}
#endif
