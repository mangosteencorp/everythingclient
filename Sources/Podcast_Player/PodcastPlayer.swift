import Foundation
import Observation
import RSS_Shared_Backend

/// Where the player is with its current episode.
public enum PodcastPlaybackState: Equatable, Sendable {
    /// Nothing is loaded.
    case idle
    /// The current episode is buffering and starts once it can play.
    case loading
    /// The current episode is playing.
    case playing
    /// The current episode is paused and resumes where it stopped.
    case paused
    /// The current episode could not be played; playing it again reloads it.
    case failed(String)
}

/// Plays one episode at a time; views observe it. Sound goes through a `PodcastAudioEngine`, `AVPlayer` by default.
/// An episode that plays to the end is unloaded, so the player returns to `idle`.
@MainActor @Observable
public final class PodcastPlayer {
    /// What the player is doing with `currentEpisode`.
    public private(set) var state: PodcastPlaybackState = .idle
    /// The loaded episode; nil when idle.
    public private(set) var currentEpisode: PodcastEpisode?
    /// The playhead, in seconds.
    public private(set) var currentTime: TimeInterval = 0
    /// The audio's length in seconds: the feed's figure until the audio reports its own, 0 when neither knows.
    public private(set) var duration: TimeInterval = 0

    private let engine: any PodcastAudioEngine

    /// Played fraction, 0...1.
    public var progress: Double {
        duration > 0 ? min(max(currentTime / duration, 0), 1) : 0
    }

    /// - Parameter engine: Plays the audio; inject a fake in tests.
    public init(engine: any PodcastAudioEngine = AVPodcastAudioEngine()) {
        self.engine = engine
        engine.onEvent = { [weak self] in self?.handle($0) }
    }

    /// Whether `episode` is the loaded one, whatever its state.
    public func isCurrent(_ episode: PodcastEpisode) -> Bool {
        currentEpisode?.id == episode.id
    }

    /// Resumes `episode` if it is the paused current one; otherwise loads it from the start.
    public func play(_ episode: PodcastEpisode) {
        guard isCurrent(episode) else { return load(episode) }
        switch state {
        case .paused:
            engine.play()
            state = .playing
        case .idle, .failed:
            load(episode)
        case .loading, .playing:
            break
        }
    }

    /// Pauses the current episode, also while it is still loading.
    public func pause() {
        guard state == .playing || state == .loading else { return }
        engine.pause()
        state = .paused
    }

    /// Pauses `episode` when it is playing or loading, plays it otherwise: what a play/pause button does.
    public func togglePlayPause(_ episode: PodcastEpisode) {
        if isCurrent(episode), state == .playing || state == .loading {
            pause()
        } else {
            play(episode)
        }
    }

    /// Moves the playhead by `seconds`, negative to go back, within the episode.
    public func skip(by seconds: TimeInterval) {
        seek(to: currentTime + seconds)
    }

    /// Moves the playhead to `time`, clamped to 0...duration.
    public func seek(to time: TimeInterval) {
        guard currentEpisode != nil else { return }
        currentTime = duration > 0 ? min(max(time, 0), duration) : max(time, 0)
        engine.seek(to: currentTime)
    }

    /// Unloads the episode and returns to `idle`.
    public func stop() {
        engine.stop()
        state = .idle
        currentEpisode = nil
        currentTime = 0
        duration = 0
    }

    private func load(_ episode: PodcastEpisode) {
        currentEpisode = episode
        currentTime = 0
        duration = episode.duration ?? 0
        state = .loading
        engine.load(episode.audioURL)
    }

    private func handle(_ event: PodcastAudioEvent) {
        switch event {
        case let .ready(duration):
            if let duration, duration > 0 { self.duration = duration }
            guard state == .loading else { return }
            engine.play()
            state = .playing
        case let .time(time):
            currentTime = time
        case .finished:
            stop()
        case let .failed(message):
            state = .failed(message)
        }
    }
}
