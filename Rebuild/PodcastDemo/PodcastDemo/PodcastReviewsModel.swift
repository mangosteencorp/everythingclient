import Foundation
import Observation
import RSS_Shared_Backend

/// IGN's review show: the feed's episodes, the search over them, and the movie review the search names exactly.
@Observable
final class PodcastReviewsModel {
    enum State: Equatable {
        case loading
        case loaded([PodcastEpisode])
        case failed(String)
    }

    private(set) var state = State.loading
    var searchText = ""

    private let feedProvider: any RSSFeedProviding
    private let feedURL: URL

    /// - Parameters:
    ///   - feedProvider: Downloads the feed; tests and fixture mode pass one that never touches the network.
    ///   - feedURL: The show to list.
    init(feedProvider: any RSSFeedProviding, feedURL: URL = PodcastFeed.ignMovieReviews) {
        self.feedProvider = feedProvider
        self.feedURL = feedURL
    }

    /// The review of the movie typed in full: "Superman" finds "Superman Review", never "Superman & Lois".
    var matchedReview: PodcastEpisode? {
        PodcastReviewMatcher.review(of: searchText, in: episodes)
    }

    /// Episodes whose title contains the search text, minus the matched review shown above them.
    var filteredEpisodes: [PodcastEpisode] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let matched = matchedReview
        return episodes.filter { (query.isEmpty || $0.title.localizedStandardContains(query)) && $0 != matched }
    }

    /// Downloads the feed, keeping the current list on screen until the new one arrives.
    func load() async {
        do {
            state = try await .loaded(feedProvider.feed(at: feedURL).episodes)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Shows the spinner again, then downloads the feed.
    func retry() async {
        state = .loading
        await load()
    }

    private var episodes: [PodcastEpisode] {
        if case let .loaded(episodes) = state { episodes } else { [] }
    }
}
