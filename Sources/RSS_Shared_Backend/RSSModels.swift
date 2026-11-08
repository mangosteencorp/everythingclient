import Foundation

/// An RSS 2.0 `<channel>` with the iTunes podcast fields this app reads.
public struct RSSFeed: Hashable, Sendable {
    /// `<title>`.
    public let title: String
    /// `<link>`: the show's website, not the feed itself.
    public let link: URL?
    /// `<description>`.
    public let description: String?
    /// `<itunes:author>`.
    public let author: String?
    /// `<itunes:image href>`, falling back to `<image><url>`.
    public let imageURL: URL?
    /// The `<item>`s in feed order, usually newest first.
    public let items: [RSSItem]

    /// Creates a feed; the parser builds these, tests and previews may too.
    public init(
        title: String,
        link: URL? = nil,
        description: String? = nil,
        author: String? = nil,
        imageURL: URL? = nil,
        items: [RSSItem] = []
    ) {
        self.title = title
        self.link = link
        self.description = description
        self.author = author
        self.imageURL = imageURL
        self.items = items
    }
}

/// One RSS `<item>`. Text is trimmed, CDATA is unwrapped, HTML is left as is.
public struct RSSItem: Identifiable, Hashable, Sendable {
    /// `<guid>`.
    public let guid: String?
    /// `<title>`, falling back to `<itunes:title>`.
    public let title: String
    /// `<link>`.
    public let link: URL?
    /// `<description>`.
    public let description: String?
    /// `<itunes:summary>`.
    public let summary: String?
    /// `<content:encoded>`, usually HTML.
    public let contentEncoded: String?
    /// `<pubDate>` (RFC 822).
    public let publishedAt: Date?
    /// `<itunes:duration>` in seconds, whether the feed wrote seconds, `mm:ss` or `hh:mm:ss`.
    public let duration: TimeInterval?
    /// `<itunes:image href>`; most items rely on the channel image instead.
    public let imageURL: URL?
    /// `<enclosure>`: the media file.
    public let enclosure: RSSEnclosure?

    /// The guid, else the enclosure URL, else the title.
    public var id: String {
        guid ?? enclosure?.url.absoluteString ?? title
    }

    /// Creates an item; the parser builds these, tests and previews may too.
    public init(
        guid: String? = nil,
        title: String,
        link: URL? = nil,
        description: String? = nil,
        summary: String? = nil,
        contentEncoded: String? = nil,
        publishedAt: Date? = nil,
        duration: TimeInterval? = nil,
        imageURL: URL? = nil,
        enclosure: RSSEnclosure? = nil
    ) {
        self.guid = guid
        self.title = title
        self.link = link
        self.description = description
        self.summary = summary
        self.contentEncoded = contentEncoded
        self.publishedAt = publishedAt
        self.duration = duration
        self.imageURL = imageURL
        self.enclosure = enclosure
    }
}

/// An item's `<enclosure>`.
public struct RSSEnclosure: Hashable, Sendable {
    /// The media file.
    public let url: URL
    /// The MIME type, e.g. `audio/mpeg`.
    public let type: String?
    /// The size in bytes as the feed states it; many feeds write `0`.
    public let length: Int?

    /// Creates an enclosure.
    public init(url: URL, type: String? = nil, length: Int? = nil) {
        self.url = url
        self.type = type
        self.length = length
    }
}
