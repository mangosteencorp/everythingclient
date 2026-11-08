import Foundation
import RSS_Shared_Backend

/// Stands in for IGN's podcast feed, so the review lookup never downloads anything.
final class StubRSSFeedProvider: RSSFeedProviding, @unchecked Sendable {
    var result: Result<RSSFeed, Error>

    private(set) var requestedURLs: [URL] = []

    init(result: Result<RSSFeed, Error> = .success(.stub())) {
        self.result = result
    }

    func feed(at url: URL) async throws -> RSSFeed {
        requestedURLs.append(url)
        // A cancelled caller gets an error, as it would from URLSession.
        try Task.checkCancellation()
        return try result.get()
    }
}

extension RSSFeed {
    /// A review show with one playable episode per title. The TV show comes before the movie, so a match on
    /// "Superman" that isn't exact would pick it.
    static func stub(
        titles: [String] = ["Clayface Review", "Superman & Lois Season 4 Review", "Superman Review"]
    ) -> RSSFeed {
        RSSFeed(title: "IGN Movie Reviews", items: titles.map { .stub(title: $0) })
    }
}

extension RSSItem {
    static func stub(title: String, guid: String? = nil, publishedAt: Date? = nil) -> RSSItem {
        RSSItem(
            guid: guid ?? title,
            title: title,
            publishedAt: publishedAt,
            enclosure: RSSEnclosure(url: URL(fileURLWithPath: "/\(guid ?? title).mp3"))
        )
    }
}
