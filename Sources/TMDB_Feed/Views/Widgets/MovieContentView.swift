import Shared_UI_Support
import SwiftUI
import TMDB_Shared_UI

@available(iOS 16, *)
struct MovieFeedTabContent<Route: Hashable>: View {
    @ObservedObject var viewModel: MovieFeedViewModel
    let feedType: MovieFeedType
    let detailRouteBuilder: (Movie) -> Route

    var body: some View {
        let movies = viewModel.movies(for: feedType)
        let isLoading = viewModel.isLoading(for: feedType)

        FeedStateView(
            phase: phase(movies: movies, isLoading: isLoading),
            isRefreshing: isLoading,
            retryAction: { viewModel.loadFeed(feedType) }
        ) {
            FeedItemsView(
                items: movies.map { $0.feedItem(route: detailRouteBuilder($0)) },
                accessibilityIdentifier: "movies_list_items",
                onItemAppear: { item in
                    viewModel.fetchMoreContentIfNeeded(currentMovieId: item.id)
                }
            )
        }
        .accessibilityIdentifier("movies_list_content")
        .refreshable {
            await viewModel.refresh(feedType)
        }
        .onAppear {
            viewModel.loadFeed(feedType)
        }
    }

    private func phase(movies: [Movie], isLoading: Bool) -> FeedLoadPhase {
        if isLoading, movies.isEmpty {
            return .loading
        }
        if let message = viewModel.errorMessage(for: feedType), movies.isEmpty {
            return .error(message: message)
        }
        return movies.isEmpty ? .empty : .loaded
    }
}

extension Movie {
    func feedItem<Route: Hashable>(route: Route) -> FeedItem<Route> {
        FeedItem(
            id: id,
            entity: toMovieRowEntity(),
            route: route,
            accessibilityIdentifier: "movielist1.movierow\(id)"
        )
    }
}
