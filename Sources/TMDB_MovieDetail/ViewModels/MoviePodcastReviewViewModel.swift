import Combine
import Foundation
import Podcast_Player
import RSS_Shared_Backend

public enum MoviePodcastReviewState: Equatable {
    case loading
    case found(PodcastEpisode)
    case notFound
    case error(String)
}

/// Finds the movie's episode of IGN's "Movie Reviews" podcast and owns the page's player for it.
@MainActor
public final class MoviePodcastReviewViewModel: ObservableObject {
    @Published var state: MoviePodcastReviewState = .loading

    /// Plays the review; owned here so it outlives the section's row being recycled while the user scrolls.
    let player: PodcastPlayer

    /// Most movies were never reviewed on the show, so no review means no section.
    var isVisible: Bool {
        state != .notFound
    }

    private let feedProvider: any RSSFeedProviding
    private let feedURL: URL
    private var loadedMovie: (title: String, releaseDate: Date?)?

    /// - Parameters:
    ///   - feedProvider: Downloads the feed; the shared service caches it, so every movie page reuses one download.
    ///   - feedURL: The review show's RSS feed.
    ///   - player: Plays the review; inject one with a silent engine in tests and previews.
    public init(
        feedProvider: any RSSFeedProviding = RSSFeedService.shared,
        feedURL: URL = PodcastFeed.ignMovieReviews,
        player: PodcastPlayer = PodcastPlayer()
    ) {
        self.feedProvider = feedProvider
        self.feedURL = feedURL
        self.player = player
    }

    /// Looks for the review of `title` once; `releaseDate` picks between remakes that share a title.
    func load(title: String, releaseDate: Date?) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, loadedMovie?.title != trimmedTitle else { return }

        loadedMovie = (trimmedTitle, releaseDate)
        await search()
    }

    /// Searches the last loaded title again, after a failure.
    func reload() async {
        guard state != .loading else { return }
        await search()
    }

    private func search() async {
        guard let movie = loadedMovie else { return }
        state = .loading

        do {
            let episodes = try await feedProvider.feed(at: feedURL).episodes
            state = PodcastReviewMatcher.review(of: movie.title, releasedOn: movie.releaseDate, in: episodes)
                .map(MoviePodcastReviewState.found) ?? .notFound
        } catch {
            // Leaving the page cancels the download. Forget the title so re-entering searches again
            // instead of showing a cancellation as a failure.
            guard !Task.isCancelled else {
                loadedMovie = nil
                return
            }
            state = .error(error.localizedDescription)
        }
    }
}
