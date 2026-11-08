import Foundation
import RSS_Shared_Backend

/// What the system shows for the loaded episode on the Lock Screen and in Control Center.
public struct PodcastNowPlayingInfo: Equatable, Sendable {
    /// The loaded episode.
    public let episode: PodcastEpisode
    /// The playhead, in seconds.
    public let elapsed: TimeInterval
    /// The audio's length in seconds; 0 when unknown.
    public let duration: TimeInterval
    /// Whether the playhead is moving; the system advances `elapsed` on its own while it is.
    public let isPlaying: Bool

    /// Creates the info for `episode`.
    public init(episode: PodcastEpisode, elapsed: TimeInterval, duration: TimeInterval, isPlaying: Bool) {
        self.episode = episode
        self.elapsed = elapsed
        self.duration = duration
        self.isPlaying = isPlaying
    }
}

/// A command from the Lock Screen, Control Center, headphones or CarPlay.
public enum PodcastRemoteCommand: Equatable, Sendable {
    /// Plays or resumes the current episode.
    case play
    /// Pauses the current episode.
    case pause
    /// Pauses when playing, plays otherwise.
    case togglePlayPause
    /// Moves the playhead by these seconds, negative to go back.
    case skip(TimeInterval)
    /// Moves the playhead to these seconds.
    case seek(TimeInterval)
}

/// Wraps the system's Now Playing controls so `PodcastPlayer` can be tested without them.
@MainActor
public protocol PodcastNowPlaying: AnyObject {
    /// Receives every remote command; the player sets it once.
    var onCommand: (@MainActor (PodcastRemoteCommand) -> Void)? { get set }
    /// Shows `info`, or clears the controls when nil.
    func update(_ info: PodcastNowPlayingInfo?)
}
