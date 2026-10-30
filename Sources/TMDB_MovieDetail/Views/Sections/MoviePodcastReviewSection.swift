import Podcast_Shared_UI
import SwiftUI

/// IGN's podcast review of the movie, playable in place. The page leaves the section out when there is none.
@available(iOS 16.0, *)
public struct MoviePodcastReviewSection: View {
    @ObservedObject var podcastReviewViewModel: MoviePodcastReviewViewModel

    public init(podcastReviewViewModel: MoviePodcastReviewViewModel) {
        self.podcastReviewViewModel = podcastReviewViewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.podcastReviewSectionTitle)
                .font(.headline)
                .accessibilityIdentifier("movieDetail.podcastReview.section")

            switch podcastReviewViewModel.state {
            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                    Text(L10n.podcastReviewLoading)
                        .foregroundStyle(.secondary)
                }

            case let .found(episode):
                PodcastEpisodeCard(episode: episode, player: podcastReviewViewModel.player)

            case let .error(message):
                SectionRetryView(message: message) {
                    await podcastReviewViewModel.reload()
                }

            case .notFound:
                EmptyView()
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview("Found") {
    TMDBMovieDetailPreviewCatalog.podcastReview.view
}

#Preview("Loading") {
    TMDBMovieDetailPreviewCatalog.podcastReviewLoading.view
}

#Preview("Error") {
    TMDBMovieDetailPreviewCatalog.podcastReviewError.view
}
#endif
