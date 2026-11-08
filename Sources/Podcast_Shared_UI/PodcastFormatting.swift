import Foundation
import RSS_Shared_Backend

/// Times and dates for podcast views, all through Apple's format styles.
enum PodcastFormatting {
    /// A playhead position: "5:14", or "1:02:03" from an hour on. Negative or unknown times read "0:00".
    static func time(_ seconds: TimeInterval) -> String {
        let seconds = seconds.isFinite ? max(seconds, 0) : 0
        return Duration.seconds(seconds).formatted(.time(pattern: seconds >= 3600 ? .hourMinuteSecond : .minuteSecond))
    }

    /// Time left, with a leading minus: "-4:00".
    static func remaining(_ seconds: TimeInterval) -> String {
        L10n.remainingTimeFormat(time(seconds))
    }

    /// The publish date and length, e.g. "Jul 10, 2025 · 9 mins"; nil when the feed gave neither.
    static func details(of episode: PodcastEpisode) -> String? {
        let parts = [
            episode.publishedAt?.formatted(date: .abbreviated, time: .omitted),
            episode.duration.map { Duration.seconds($0).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)) },
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: L10n.episodeDetailsSeparator)
    }
}
