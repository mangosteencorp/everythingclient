import Foundation
@testable import RSS_Shared_Backend
import Testing

struct PodcastEpisodeTests {
    @Test func mapsEveryItemWithAnEnclosure() throws {
        let feed = try ignFixtureFeed()
        let episodes = feed.episodes
        #expect(episodes.count == 6)
        #expect(!episodes.contains { $0.id == "trailer-without-enclosure" })

        let clayface = try #require(episodes.first)
        let item = try #require(feed.items.first)
        #expect(clayface.id == item.id)
        #expect(clayface.title == "Clayface Review")
        #expect(clayface.summary == item.summary)
        #expect(clayface.publishedAt == item.publishedAt)
        #expect(clayface.duration == 314)
        #expect(clayface.audioURL == item.enclosure?.url)
        #expect(clayface.podcastTitle == "IGN Movie Reviews")
    }

    @Test func artworkPrefersTheItemImageOverTheChannelImage() throws {
        let feed = try ignFixtureFeed()
        let episodes = feed.episodes
        #expect(episodes.first?.artworkURL == feed.imageURL)
        let adventures = try #require(episodes.first { $0.title == "My Adventures With Superman Review" })
        #expect(adventures.artworkURL != feed.imageURL)
        #expect(adventures.artworkURL == feed.items.first { $0.id == adventures.id }?.imageURL)
    }

    @Test func summaryFallsBackToDescription() throws {
        let item = RSSItem(title: "A", description: "Plain description", enclosure: RSSEnclosure(url: URL(fileURLWithPath: "/a.mp3")))
        #expect(PodcastEpisode(item: item, feed: RSSFeed(title: "Show"))?.summary == "Plain description")
    }

    @Test func isNilWithoutAnEnclosure() {
        #expect(PodcastEpisode(item: RSSItem(title: "Trailer"), feed: RSSFeed(title: "Show")) == nil)
    }
}
