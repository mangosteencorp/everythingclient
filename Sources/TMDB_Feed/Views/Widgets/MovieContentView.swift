import Shared_UI_Support
import SwiftUI
import TMDB_Shared_UI

@available(iOS 16, *)
struct MovieFeedTabContent<Route: Hashable>: View {
    @ObservedObject var viewModel: MovieFeedViewModel
    let feedType: MovieFeedType
    let detailRouteBuilder: (Movie) -> Route
    @Binding var useFancyDesign: Bool

    var body: some View {
        let movies = viewModel.movies(for: feedType)
        Group {
            if viewModel.isLoading(for: feedType), movies.isEmpty {
                ProgressView(L10n.playingLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage(for: feedType), movies.isEmpty {
                FeedErrorContentView(
                    message: message,
                    allowsCancelSearch: false,
                    retryAction: { viewModel.loadFeed(feedType) },
                    cancelAction: nil
                )
            } else if movies.isEmpty {
                CommonNoResultView(
                    configuration: NoResultViewConfiguration(
                        primaryButtonAction: { [weak viewModel] in
                            viewModel?.loadFeed(feedType)
                        }
                    ),
                    useFancyDesign: $useFancyDesign
                )
            } else {
                List(movies) { movie in
                    NavigationMovieRow(viewModel, movie: movie, routeBuilder: detailRouteBuilder)
                }
                .overlay {
                    if viewModel.isLoading(for: feedType) {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.05))
                    }
                }
            }
        }
        .accessibilityIdentifier("movies_list_content")
        .refreshable {
            await viewModel.refresh(feedType)
        }
        .onAppear {
            if movies.isEmpty, !viewModel.isLoading(for: feedType) {
                viewModel.loadFeed(feedType)
            }
        }
    }
}
