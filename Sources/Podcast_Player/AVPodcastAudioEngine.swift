import AVFoundation

/// Streams with `AVPlayer` under the `.playback` audio session category, so audio plays with the silent switch on.
/// Observers live as long as the loaded item: `load(_:)` adds them, `stop()` and `deinit` remove them.
@MainActor
public final class AVPodcastAudioEngine: PodcastAudioEngine {
    /// Receives readiness, the time every half second, the end and failures, on the main actor.
    public var onEvent: (@MainActor (PodcastAudioEvent) -> Void)?

    private let player = AVPlayer()
    private var statusObservation: NSKeyValueObservation?
    // Only touched on the main actor, and by `deinit` once nothing else can reach the engine.
    private nonisolated(unsafe) var timeObserver: Any?
    private nonisolated(unsafe) var endObserver: (any NSObjectProtocol)?

    /// Creates an engine with nothing loaded.
    public init() {}

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }

    /// Unloads the current item, then observes and loads the new one.
    public func load(_ url: URL) {
        stop()
        let item = AVPlayerItem(url: url)
        statusObservation = item.observe(\.status) { @Sendable [weak self] item, _ in
            let event: PodcastAudioEvent? = switch item.status {
            case .readyToPlay: .ready(duration: item.duration.seconds.isFinite ? item.duration.seconds : nil)
            case .failed: .failed(item.error?.localizedDescription ?? "")
            default: nil
            }
            guard let event else { return }
            Task { @MainActor in self?.onEvent?(event) }
        }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated { self?.onEvent?(.time(time.seconds)) }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.onEvent?(.finished) }
        }
        player.replaceCurrentItem(with: item)
    }

    /// Switches the audio session to spoken-word playback, then plays.
    public func play() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        #endif
        player.play()
    }

    /// Pauses the player.
    public func pause() {
        player.pause()
    }

    /// Seeks the player.
    public func seek(to time: TimeInterval) {
        player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    /// Pauses, unloads the item and removes its observers.
    public func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        statusObservation = nil
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        timeObserver = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
    }
}
