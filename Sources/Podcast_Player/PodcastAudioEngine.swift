import Foundation

/// What an audio engine reports back to the player.
public enum PodcastAudioEvent: Equatable, Sendable {
    /// The audio can play; `duration` is nil when the stream doesn't know its length.
    case ready(duration: TimeInterval?)
    /// The playhead moved, in seconds.
    case time(TimeInterval)
    /// Playback reached the end.
    case finished
    /// The audio could not be loaded or played.
    case failed(String)
}

/// Wraps the system audio player so `PodcastPlayer` can be tested and previewed without sound.
@MainActor
public protocol PodcastAudioEngine: AnyObject {
    /// Receives every event; the player sets it once.
    var onEvent: (@MainActor (PodcastAudioEvent) -> Void)? { get set }
    /// Replaces whatever is loaded with `url`, paused; `.ready` follows once it can play.
    func load(_ url: URL)
    /// Starts or resumes playback.
    func play()
    /// Pauses playback.
    func pause()
    /// Moves the playhead to `time` seconds.
    func seek(to time: TimeInterval)
    /// Stops playback and unloads the audio.
    func stop()
}
