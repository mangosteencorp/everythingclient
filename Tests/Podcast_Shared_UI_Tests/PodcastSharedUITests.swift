import Foundation
import Podcast_Player
@testable import Podcast_Shared_UI
import RSS_Shared_Backend
import Testing

struct PodcastFormattingTests {
    @Test(arguments: [
        (0.0, "0:00"),
        (314, "5:14"),
        (3599, "59:59"),
        (3723, "1:02:03"),
        (-5, "0:00"),
        (.nan, "0:00"),
    ])
    func formatsPlayheadTimes(seconds: TimeInterval, expected: String) {
        #expect(PodcastFormatting.time(seconds) == expected)
    }

    @Test func prefixesRemainingTimeWithAMinus() {
        #expect(PodcastFormatting.remaining(240) == "-4:00")
        #expect(PodcastFormatting.remaining(-1) == "-0:00")
    }

    @Test func detailsJoinDateAndLength() {
        let date = Date(timeIntervalSince1970: 1_752_147_000)
        let episode = PodcastEpisode(id: "a", title: "A", publishedAt: date, duration: 557, audioURL: URL(fileURLWithPath: "/a.mp3"), podcastTitle: "Show")
        let expected = date.formatted(date: .abbreviated, time: .omitted) + L10n.episodeDetailsSeparator + Duration.seconds(557)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
        #expect(PodcastFormatting.details(of: episode) == expected)
    }

    @Test func detailsAreNilWithoutDateOrLength() {
        let episode = PodcastEpisode(id: "a", title: "A", audioURL: URL(fileURLWithPath: "/a.mp3"), podcastTitle: "Show")
        #expect(PodcastFormatting.details(of: episode) == nil)
    }
}

struct PodcastPlayButtonModeTests {
    @Test(arguments: [
        (false, PodcastPlaybackState.playing, PodcastPlayButtonMode.play),
        (false, .loading, .play),
        (true, .idle, .play),
        (true, .loading, .loading),
        (true, .playing, .pause),
        (true, .paused, .play),
        (true, .failed("Offline"), .play),
    ])
    func mapsPlayerStateToMode(isCurrent: Bool, state: PodcastPlaybackState, expected: PodcastPlayButtonMode) {
        #expect(PodcastPlayButtonMode(isCurrent: isCurrent, state: state) == expected)
    }

    @Test func eachModeHasItsIconAndLabel() {
        #expect(PodcastPlayButtonMode.play.systemImage == "play.circle.fill")
        #expect(PodcastPlayButtonMode.pause.systemImage == "pause.circle.fill")
        #expect(PodcastPlayButtonMode.loading.systemImage == nil)
        #expect(PodcastPlayButtonMode.play.accessibilityLabel == "Play")
        #expect(PodcastPlayButtonMode.pause.accessibilityLabel == "Pause")
        #expect(PodcastPlayButtonMode.loading.accessibilityLabel == "Loading")
    }
}
