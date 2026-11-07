import Foundation
@testable import Podcast_Player
import RSS_Shared_Backend
import Testing

@MainActor
final class FakeNowPlaying: PodcastNowPlaying {
    var onCommand: (@MainActor (PodcastRemoteCommand) -> Void)?
    private(set) var updates: [PodcastNowPlayingInfo?] = []

    func update(_ info: PodcastNowPlayingInfo?) { updates.append(info) }

    func send(_ command: PodcastRemoteCommand) {
        onCommand?(command)
    }
}

private let review = PodcastEpisode(
    id: "review", title: "Superman Review", duration: 600, audioURL: URL(fileURLWithPath: "/review.mp3"), podcastTitle: "IGN"
)

@MainActor
struct PodcastNowPlayingTests {
    private let engine = FakeAudioEngine()
    private let nowPlaying = FakeNowPlaying()
    private let player: PodcastPlayer

    init() {
        player = PodcastPlayer(engine: engine, nowPlaying: nowPlaying)
    }

    /// Loads `review` and reports it ready, leaving it playing.
    private func playReady() {
        player.play(review)
        engine.send(.ready(duration: 612))
    }

    @Test func showsTheEpisodeWhileLoadingThenPlaying() {
        player.play(review)
        #expect(nowPlaying.updates.last == PodcastNowPlayingInfo(episode: review, elapsed: 0, duration: 600, isPlaying: false))
        engine.send(.ready(duration: 612))
        #expect(nowPlaying.updates.last == PodcastNowPlayingInfo(episode: review, elapsed: 0, duration: 612, isPlaying: true))
    }

    @Test func pausingShowsTheEpisodeStoppedWhereItPaused() {
        playReady()
        engine.send(.time(42))
        player.pause()
        #expect(nowPlaying.updates.last == PodcastNowPlayingInfo(episode: review, elapsed: 42, duration: 612, isPlaying: false))
    }

    @Test func timeTicksDoNotPublish() {
        playReady()
        let count = nowPlaying.updates.count
        engine.send(.time(1))
        engine.send(.time(1.5))
        #expect(nowPlaying.updates.count == count)
    }

    @Test func stoppingClearsTheControls() {
        playReady()
        player.stop()
        #expect(nowPlaying.updates.last == .some(nil))
    }

    @Test func finishingClearsTheControls() {
        playReady()
        engine.send(.finished)
        #expect(nowPlaying.updates.last == .some(nil))
    }

    @Test func failingShowsTheEpisodeStopped() {
        player.play(review)
        engine.send(.failed("offline"))
        #expect(nowPlaying.updates.last == PodcastNowPlayingInfo(episode: review, elapsed: 0, duration: 600, isPlaying: false))
    }

    @Test func playPauseCommandsDriveThePlayer() {
        playReady()
        nowPlaying.send(.pause)
        #expect(player.state == .paused)
        nowPlaying.send(.play)
        #expect(player.state == .playing)
        nowPlaying.send(.togglePlayPause)
        #expect(player.state == .paused)
        nowPlaying.send(.togglePlayPause)
        #expect(player.state == .playing)
        #expect(engine.calls == [.load(review.audioURL), .play, .pause, .play, .pause, .play])
    }

    @Test func skipAndSeekCommandsMoveThePlayhead() {
        playReady()
        nowPlaying.send(.seek(100))
        #expect(player.currentTime == 100)
        #expect(nowPlaying.updates.last??.elapsed == 100)
        nowPlaying.send(.skip(-15))
        #expect(player.currentTime == 85)
        #expect(engine.calls.last == .seek(85))
    }

    @Test func commandsDoNothingWhenIdle() {
        nowPlaying.send(.play)
        nowPlaying.send(.togglePlayPause)
        nowPlaying.send(.pause)
        nowPlaying.send(.skip(30))
        nowPlaying.send(.seek(10))
        #expect(player.state == .idle)
        #expect(engine.calls.isEmpty)
        #expect(nowPlaying.updates.isEmpty)
    }
}
