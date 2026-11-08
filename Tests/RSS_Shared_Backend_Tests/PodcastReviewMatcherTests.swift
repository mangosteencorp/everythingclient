import Foundation
@testable import RSS_Shared_Backend
import Testing

struct PodcastReviewMatcherTests {
    private let episodes: [PodcastEpisode]

    init() throws {
        episodes = try ignFixtureFeed().episodes
    }

    private func episode(_ title: String, publishedAt: Date? = nil) -> PodcastEpisode {
        PodcastEpisode(id: title, title: title, publishedAt: publishedAt, audioURL: URL(fileURLWithPath: "/a.mp3"), podcastTitle: "Show")
    }

    @Test func findsSupermanAndSkipsTheShowsNamedAfterHim() {
        let review = PodcastReviewMatcher.review(of: "Superman", in: episodes)
        #expect(review?.title == "Superman Review")
        #expect(review?.id == "d21ef8e2-5d43-11f0-a2b5-b722f5402f9d")
    }

    @Test(arguments: ["Superman & Lois Season 4", "superman and lois: season 4"])
    func treatsAmpersandAsAndAndIgnoresPunctuation(title: String) {
        #expect(PodcastReviewMatcher.review(of: title, in: episodes)?.title == "Superman & Lois Season 4 Review")
    }

    @Test func ignoresCaseAndAccents() {
        #expect(PodcastReviewMatcher.review(of: "SUPERMAN", in: episodes)?.title == "Superman Review")
        let joker = episode("Joker: Folie à Deux Review")
        #expect(PodcastReviewMatcher.review(of: "Joker: Folie a Deux", in: [joker]) == joker)
        #expect(PodcastReviewMatcher.review(of: "JOKER – FOLIE À DEUX", in: [joker]) == joker)
    }

    @Test func matchesTitlesWithoutTheReviewSuffix() {
        let bridget = episode("Bridget Jones: Mad About the Boy ")
        let lowercase = episode("IF review")
        #expect(PodcastReviewMatcher.review(of: "Bridget Jones: Mad About the Boy", in: [bridget]) == bridget)
        #expect(PodcastReviewMatcher.review(of: "IF", in: [lowercase]) == lowercase)
    }

    @Test func picksThePublishDateClosestToTheRelease() {
        let remake = PodcastReviewMatcher.review(of: "Silent Night", releasedOn: Date(timeIntervalSince1970: 1_701_388_800), in: episodes)
        let original = PodcastReviewMatcher.review(of: "Silent Night", releasedOn: Date(timeIntervalSince1970: 1_633_046_400), in: episodes)
        #expect(remake?.id == "449a42e8-8daa-11ee-97ee-0bb896546b87")
        #expect(original?.id == "55db7637-b06d-4efc-8dd6-0bb8ffb1bace")
    }

    @Test func picksTheNewestWithoutAReleaseDate() {
        #expect(PodcastReviewMatcher.review(of: "Silent Night", in: episodes)?.id == "449a42e8-8daa-11ee-97ee-0bb896546b87")
        let undated = episode("Dune Review")
        let dated = episode("Dune Review", publishedAt: Date(timeIntervalSince1970: 0))
        #expect(PodcastReviewMatcher.review(of: "Dune", in: [undated, dated]) == dated)
    }

    @Test(arguments: ["Batman", "Superman Returns", "Lois", "", "  ", "Review"])
    func returnsNilWithoutAnExactMatch(title: String) {
        #expect(PodcastReviewMatcher.review(of: title, in: episodes) == nil)
    }
}
