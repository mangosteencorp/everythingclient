import Foundation

/// Why a document could not be read as an RSS feed.
public enum RSSParserError: Error, Equatable, Sendable {
    /// The data is not well-formed XML, e.g. an HTML error page.
    case malformedXML
    /// Well-formed XML without an `<rss><channel>`, e.g. an Atom feed.
    case missingChannel
}

/// Parses RSS 2.0 with the iTunes podcast and `content:encoded` extensions. Atom and RSS 1.0 are not supported.
public struct RSSParser: Sendable {
    /// Creates a parser; it holds no state, so one can be shared.
    public init() {}

    /// Parses a whole feed document.
    /// - Throws: `RSSParserError`.
    public func parse(_ data: Data) throws -> RSSFeed {
        let delegate = RSSParserDelegate()
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.delegate = delegate
        guard parser.parse() else { throw RSSParserError.malformedXML }
        guard let channel = delegate.channel else { throw RSSParserError.missingChannel }
        return RSSFeed(
            title: channel["title"] ?? "",
            link: channel.url("link"),
            description: channel["description"],
            author: channel["itunes:author"],
            imageURL: channel.url("itunes:image@href") ?? channel.url("image/url"),
            items: delegate.items
        )
    }
}

/// Collects each element's trimmed text, and each attribute as `element@attribute`, keyed by its path below
/// `<channel>` or `<item>` (`image/url`, `itunes:duration`, `enclosure@url`). The first non-empty value wins.
private final class RSSParserDelegate: NSObject, XMLParserDelegate {
    /// Known namespaces get their conventional prefix whatever the feed declared; any other keeps its URI,
    /// so `atom:link` or `media:title` can never pass for `<link>` or `<title>`.
    private static let prefixes = [
        "http://www.itunes.com/dtds/podcast-1.0.dtd": "itunes",
        "http://purl.org/rss/1.0/modules/content/": "content",
    ]

    private(set) var channel: [String: String]?
    private(set) var items: [RSSItem] = []
    private var item: [String: String]?
    private var path: [String] = []
    private var text = ""
    private let dateFormatters = ["d MMM yyyy HH:mm:ss zzz", "d MMM yyyy HH:mm zzz"].map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }

    /// The current element's path below `<item>` or `<channel>`; empty for those two themselves.
    private var key: String? {
        channel == nil ? nil : path.dropFirst(item == nil ? 2 : 3).joined(separator: "/")
    }

    func parser(
        _: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName _: String?,
        attributes: [String: String]
    ) {
        path.append(Self.name(elementName, namespaceURI))
        text = ""
        if path == ["rss", "channel"] { channel = [:] }
        if path == ["rss", "channel", "item"] { item = [:] }
        guard let key, !key.isEmpty else { return }
        for (attribute, value) in attributes {
            store(value, for: "\(key)@\(attribute)")
        }
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_: XMLParser, foundCDATA CDATABlock: Data) {
        text += String(bytes: CDATABlock, encoding: .utf8) ?? ""
    }

    func parser(_: XMLParser, didEndElement _: String, namespaceURI _: String?, qualifiedName _: String?) {
        if let key, !key.isEmpty { store(text.trimmingCharacters(in: .whitespacesAndNewlines), for: key) }
        if path == ["rss", "channel", "item"], let item {
            items.append(makeItem(item))
            self.item = nil
        }
        path.removeLast()
        text = ""
    }

    private func store(_ value: String, for key: String) {
        guard !value.isEmpty else { return }
        if item != nil {
            if item?[key] == nil { item?[key] = value }
        } else if channel?[key] == nil {
            channel?[key] = value
        }
    }

    private func makeItem(_ fields: [String: String]) -> RSSItem {
        RSSItem(
            guid: fields["guid"],
            title: fields["title"] ?? fields["itunes:title"] ?? "",
            link: fields.url("link"),
            description: fields["description"],
            summary: fields["itunes:summary"],
            contentEncoded: fields["content:encoded"],
            publishedAt: fields["pubDate"].flatMap(date),
            duration: fields["itunes:duration"].flatMap(Self.duration),
            imageURL: fields.url("itunes:image@href"),
            enclosure: fields.url("enclosure@url").map {
                RSSEnclosure(url: $0, type: fields["enclosure@type"], length: fields["enclosure@length"].flatMap { Int($0) })
            }
        )
    }

    /// RFC 822 with or without the weekday and the seconds, with a numeric offset (`-0000`) or a zone name (`GMT`, `EST`).
    private func date(_ string: String) -> Date? {
        let withoutWeekday = (string.split(separator: ",", maxSplits: 1).last.map(String.init) ?? string)
            .trimmingCharacters(in: .whitespaces)
        return dateFormatters.lazy.compactMap { $0.date(from: withoutWeekday) }.first
    }

    /// Seconds, `mm:ss` or `hh:mm:ss`.
    private static func duration(_ string: String) -> TimeInterval? {
        let fields = string.split(separator: ":", omittingEmptySubsequences: false)
        let parts = fields.compactMap { TimeInterval($0) }
        guard (1...3).contains(fields.count), parts.count == fields.count else { return nil }
        return parts.reduce(0) { $0 * 60 + $1 }
    }

    private static func name(_ localName: String, _ namespaceURI: String?) -> String {
        guard let namespaceURI, !namespaceURI.isEmpty else { return localName }
        return "\(prefixes[namespaceURI.lowercased()] ?? namespaceURI):\(localName)"
    }
}

private extension [String: String] {
    func url(_ key: String) -> URL? {
        self[key].flatMap { URL(string: $0) }
    }
}
