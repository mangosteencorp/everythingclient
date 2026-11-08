import Foundation
@testable import RSS_Shared_Backend
import Testing

struct RSSParserTests {
    private let channelImage = "https://megaphone.imgix.net/podcasts/f0057306-360b-11ee-ad6c-eb430e5f70e1/image/image.jpg?ixlib=rails-4.3.1&max-w=3000&max-h=3000&fit=crop&auto=format,compress"

    @Test func parsesChannelFieldsAndIgnoresAtomLink() throws {
        let feed = try ignFixtureFeed()
        #expect(feed.title == "IGN Movie Reviews")
        #expect(feed.link?.absoluteString == "https://ign.com")
        #expect(feed.description == "Reviews for the hottest movies of the year from IGN.")
        #expect(feed.author == "IGN")
        #expect(feed.imageURL?.absoluteString == channelImage)
        #expect(feed.items.count == 7)
    }

    @Test func parsesItemFieldsAndUnwrapsCDATA() throws {
        let item = try #require(try ignFixtureFeed().items.first)
        #expect(item.guid == "811bfdda-ce96-11f1-9e30-f334abf3d578")
        #expect(item.id == item.guid)
        #expect(item.title == "Clayface Review")
        #expect(item.link == nil)
        #expect(item.description?.hasPrefix("The DCU’s first horror film is a fun, gritty and gruesome throwback.\n") == true)
        #expect(item.summary == item.description)
        #expect(item.contentEncoded?.hasPrefix("<p>The DCU’s first horror film") == true)
        #expect(item.publishedAt == Date(timeIntervalSince1970: 1_793_268_000))
        #expect(item.duration == 314)
        #expect(item.imageURL == nil)
        #expect(item.enclosure == RSSEnclosure(
            url: try #require(URL(string: "https://mgln.ai/e/211/traffic.megaphone.fm/AIRWV4108270627.mp3")),
            type: "audio/mpeg",
            length: 0
        ))
    }

    @Test func readsOptionalItemLinkImageAndEntities() throws {
        let items = try ignFixtureFeed().items
        let adventures = try #require(items.first { $0.title == "My Adventures With Superman Review" })
        #expect(adventures.link?.absoluteString == "https://omny.fm/shows/ign-movie-reviews-1/my-adventures-with-superman-review")
        #expect(adventures.imageURL?.absoluteString.hasPrefix("https://megaphone.imgix.net/podcasts/f4b6b31a") == true)
        #expect(items.contains { $0.title == "Superman & Lois Season 4 Review" })
    }

    @Test func keepsItemWithoutEnclosure() throws {
        let item = try #require(try ignFixtureFeed().items.last)
        #expect(item.title == "Coming Soon: IGN Movie Reviews")
        #expect(item.enclosure == nil)
        #expect(item.id == "trailer-without-enclosure")
    }

    @Test(arguments: [
        ("Thu, 29 Oct 2026 10:00:00 -0000", 1_793_268_000.0),
        ("29 Oct 2026 10:00:00 +0000", 1_793_268_000),
        ("Thu, 29 Oct 2026 10:00:00 GMT", 1_793_268_000),
        ("Thu, 29 Oct 2026 06:00:00 EDT", 1_793_268_000),
        ("Thu, 29 Oct 2026 15:30:00 +0530", 1_793_268_000),
        ("Thu, 29 Oct 2026 10:00 GMT", 1_793_268_000),
        ("Thu, 9 Oct 2026 10:00:00 -0000", 1_791_540_000),
    ])
    func parsesRFC822Dates(pubDate: String, expected: TimeInterval) throws {
        let item = try #require(try parseFeed(item: "<title>A</title><pubDate>\(pubDate)</pubDate>").items.first)
        #expect(item.publishedAt == Date(timeIntervalSince1970: expected))
    }

    @Test func leavesUnreadableDateNil() throws {
        let item = try #require(try parseFeed(item: "<title>A</title><pubDate>last Thursday</pubDate>").items.first)
        #expect(item.publishedAt == nil)
    }

    @Test(arguments: [
        ("314", 314.0),
        ("05:14", 314),
        ("1:02:03", 3723),
        ("90.5", 90.5),
    ])
    func parsesDurations(duration: String, expected: TimeInterval) throws {
        let item = try #require(try parseFeed(item: "<title>A</title><itunes:duration>\(duration)</itunes:duration>").items.first)
        #expect(item.duration == expected)
    }

    @Test(arguments: ["", "abc", "1:2:3:4", "5:"])
    func leavesUnreadableDurationNil(duration: String) throws {
        let item = try #require(try parseFeed(item: "<title>A</title><itunes:duration>\(duration)</itunes:duration>").items.first)
        #expect(item.duration == nil)
    }

    @Test func readsITunesFieldsUnderAnyPrefix() throws {
        let feed = try RSSParser().parse(Data("""
        <rss version="2.0" xmlns:it="http://www.itunes.com/DTDs/Podcast-1.0.dtd">
          <channel><title>Show</title><it:author>Host</it:author>
            <item><it:title>Fallback Title</it:title><it:duration>60</it:duration></item>
          </channel>
        </rss>
        """.utf8))
        #expect(feed.author == "Host")
        #expect(feed.items.first?.title == "Fallback Title")
        #expect(feed.items.first?.duration == 60)
    }

    @Test func channelImageFallsBackToImageElement() throws {
        let feed = try parseFeed(channel: "<image><url>https://show.test/art.jpg</url><title>Art</title></image>", item: "<title>A</title>")
        #expect(feed.imageURL?.absoluteString == "https://show.test/art.jpg")
        #expect(feed.title == "Show")
    }

    @Test func rejectsMalformedXML() {
        #expect(throws: RSSParserError.malformedXML) {
            try RSSParser().parse(Data("<rss><channel><title>Broken</channel>".utf8))
        }
    }

    @Test(arguments: [
        "<html><body><p>Not found</p></body></html>",
        #"<feed xmlns="http://www.w3.org/2005/Atom"><title>Atom</title></feed>"#,
    ])
    func rejectsDocumentsWithoutRSSChannel(document: String) {
        #expect(throws: RSSParserError.missingChannel) { try RSSParser().parse(Data(document.utf8)) }
    }
}
