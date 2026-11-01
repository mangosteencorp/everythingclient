import Foundation
@testable import Podcast_Player
import RSS_Shared_Backend
import Testing

@MainActor
final class FakeAudioEngine: PodcastAudioEngine {
    enum Call: Equatable {
        case load(URL)
        case play
        case pause
        case seek(TimeInterval)
        case stop
    }

    var onEvent: (@MainActor (PodcastAudioEvent) -> Void)?
    private(set) var calls: [Call] = []

    func load(_ url: URL) { calls.append(.load(url)) }
    func play() { calls.append(.play) }
    func pause() { calls.append(.pause) }
    func seek(to time: TimeInterval) { calls.append(.seek(time)) }
    func stop() { calls.append(.stop) }

    func send(_ event: PodcastAudioEvent) {
        onEvent?(event)
    }
}

private let superman = PodcastEpisode(
    id: "superman", title: "Superman Review", duration: 600, audioURL: URL(fileURLWithPath: "/superman.mp3"), podcastTitle: "IGN"
)
private let clayface = PodcastEpisode(
    id: "clayface", title: "Clayface Review", audioURL: URL(fileURLWithPath: "/clayface.mp3"), podcastTitle: "IGN"
)

@MainActor
struct PodcastPlayerTests {
    private let engine = FakeAudioEngine()
    private let player: PodcastPlayer

    init() {
        player = PodcastPlayer(engine: engine)
    }

    /// Loads `episode` and reports it ready, leaving it playing.
    private func playReady(_ episode: PodcastEpisode = superman, duration: TimeInterval? = nil) {
        player.play(episode)
        engine.send(.ready(duration: duration))
    }

    @Test func playLoadsThenPlaysOnceReady() {
        player.play(superman)
        #expect(engine.calls == [.load(superman.audioURL)])
        #expect(player.state == .loading)
        #expect(player.currentEpisode == superman)
        #expect(player.duration == 600)

        engine.send(.ready(duration: 612))
        #expect(engine.calls == [.load(superman.audioURL), .play])
        #expect(player.state == .playing)
        #expect(player.duration == 612)
    }

    @Test func keepsTheFeedDurationWhenTheStreamHasNone() {
        playReady(duration: nil)
        #expect(player.duration == 600)
    }

    @Test func pauseAndResumeOfTheSameEpisodeDoesNotReload() {
        playReady()
        player.pause()
        #expect(player.state == .paused)
        player.play(superman)
        #expect(player.state == .playing)
        #expect(engine.calls == [.load(superman.audioURL), .play, .pause, .play])
    }

    @Test func playingTheCurrentEpisodeAgainDoesNothing() {
        playReady()
        player.play(superman)
        #expect(engine.calls == [.load(superman.audioURL), .play])
    }

    @Test func togglePlayPauseAlternates() {
        player.togglePlayPause(superman)
        #expect(player.state == .loading)
        engine.send(.ready(duration: nil))
        player.togglePlayPause(superman)
        #expect(player.state == .paused)
        player.togglePlayPause(superman)
        #expect(player.state == .playing)
    }

    @Test func pausingWhileLoadingStaysPausedOnceReady() {
        player.play(superman)
        player.pause()
        engine.send(.ready(duration: 612))
        #expect(player.state == .paused)
        #expect(player.duration == 612)
        #expect(engine.calls == [.load(superman.audioURL), .pause])
    }

    @Test func playingAnotherEpisodeReloads() {
        playReady()
        engine.send(.time(120))
        player.play(clayface)
        #expect(engine.calls.last == .load(clayface.audioURL))
        #expect(player.currentEpisode == clayface)
        #expect(player.state == .loading)
        #expect(player.currentTime == 0)
        #expect(player.duration == 0)
        #expect(!player.isCurrent(superman))
        #expect(player.isCurrent(clayface))
    }

    @Test func skipIsClampedToTheEpisode() {
        playReady()
        engine.send(.time(590))
        player.skip(by: 30)
        #expect(player.currentTime == 600)
        #expect(engine.calls.last == .seek(600))
        player.skip(by: -700)
        #expect(player.currentTime == 0)
        #expect(engine.calls.last == .seek(0))
    }

    @Test func seekWithoutAnEpisodeDoesNothing() {
        player.seek(to: 30)
        #expect(player.currentTime == 0)
        #expect(engine.calls.isEmpty)
    }

    @Test func timeUpdatesProgress() {
        playReady()
        engine.send(.time(150))
        #expect(player.currentTime == 150)
        #expect(player.progress == 0.25)
    }

    @Test func finishingUnloadsTheEpisode() {
        playReady()
        engine.send(.finished)
        #expect(player.state == .idle)
        #expect(player.currentEpisode == nil)
        #expect(player.progress == 0)
        #expect(engine.calls.last == .stop)
    }

    @Test func failureKeepsTheEpisodeAndPlayReloads() {
        player.play(superman)
        engine.send(.failed("Offline"))
        #expect(player.state == .failed("Offline"))
        #expect(player.isCurrent(superman))
        player.play(superman)
        #expect(player.state == .loading)
        #expect(engine.calls == [.load(superman.audioURL), .load(superman.audioURL)])
    }

    @Test func stopResetsEverything() {
        playReady()
        engine.send(.time(42))
        player.stop()
        #expect(player.state == .idle)
        #expect(player.currentEpisode == nil)
        #expect(player.currentTime == 0)
        #expect(player.duration == 0)
        #expect(engine.calls.last == .stop)
    }

    @Test func previewPlayersStartInTheRequestedState() {
        #expect(PodcastPlayer.preview().state == .idle)
        #expect(PodcastPlayer.preview(.loading).state == .loading)
        let paused = PodcastPlayer.preview(.paused, episode: superman, elapsed: 60)
        #expect(paused.state == .paused)
        #expect(paused.currentTime == 60)
        #expect(paused.progress == 0.1)
        #expect(PodcastPlayer.preview(.playing).state == .playing)
        #expect(PodcastPlayer.preview(.failed("Offline")).state == .failed("Offline"))
    }
}
