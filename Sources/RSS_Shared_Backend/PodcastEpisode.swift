import Foundation

/// A playable podcast episode: an RSS item that has an audio enclosure, with the channel's details folded in.
public struct PodcastEpisode: Identifiable, Hashable, Sendable {
    /// The item's id: its guid, else its audio URL.
    public let id: String
    /// The episode title, e.g. "Superman Review".
    public let title: String
    /// `<itunes:summary>`, falling back to `<description>`; plain text in most feeds.
    public let summary: String?
    /// When the episode was published.
    public let publishedAt: Date?
    /// The length the feed states, in seconds; the player replaces it with the real one once audio loads.
    public let duration: TimeInterval?
    /// The enclosure to stream.
    public let audioURL: URL
    /// The episode's own artwork, else the show's.
    public let artworkURL: URL?
    /// The show's title, e.g. "IGN Movie Reviews".
    public let podcastTitle: String

    /// Creates an episode; previews and tests build these by hand.
    public init(
        id: String,
        title: String,
        summary: String? = nil,
        publishedAt: Date? = nil,
        duration: TimeInterval? = nil,
        audioURL: URL,
        artworkURL: URL? = nil,
        podcastTitle: String
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.publishedAt = publishedAt
        self.duration = duration
        self.audioURL = audioURL
        self.artworkURL = artworkURL
        self.podcastTitle = podcastTitle
    }

    /// The episode for `item`, or nil when it has no enclosure to play.
    public init?(item: RSSItem, feed: RSSFeed) {
        guard let audioURL = item.enclosure?.url else { return nil }
        self.init(
            id: item.id,
            title: item.title,
            summary: item.summary ?? item.description,
            publishedAt: item.publishedAt,
            duration: item.duration,
            audioURL: audioURL,
            artworkURL: item.imageURL ?? feed.imageURL,
            podcastTitle: feed.title
        )
    }
}

public extension RSSFeed {
    /// Every item that has an enclosure, in feed order.
    var episodes: [PodcastEpisode] {
        items.compactMap { PodcastEpisode(item: $0, feed: self) }
    }
}

#if DEBUG
public extension PodcastEpisode {
    /// A sample review episode for previews; nothing it points at is ever loaded.
    static let preview = PodcastEpisode(
        id: "preview-superman",
        title: "Superman Review",
        summary: "Our critic weighs in on the new Superman, from the casting to the third act.",
        publishedAt: Date(timeIntervalSince1970: 1_752_147_000),
        duration: 557,
        audioURL: URL(fileURLWithPath: "/dev/null"),
        podcastTitle: "IGN Movie Reviews"
    )

    /// A few sample episodes for list previews, starting with `preview`.
    static let previews = [
        preview,
        PodcastEpisode(
            id: "preview-clayface",
            title: "Clayface Review",
            summary: "A horror-tinged DC villain story gets its own feature.",
            publishedAt: Date(timeIntervalSince1970: 1_793_268_000),
            duration: 314,
            audioURL: URL(fileURLWithPath: "/dev/null"),
            podcastTitle: "IGN Movie Reviews"
        ),
        PodcastEpisode(
            id: "preview-long",
            title: "The 25 Best Comedy Movies of All Time, a Very Long Episode Title That Wraps",
            publishedAt: nil,
            duration: 3723,
            audioURL: URL(fileURLWithPath: "/dev/null"),
            podcastTitle: "IGN Movie Reviews"
        ),
    ]
}
#endif
