import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16, *)
struct TVShowFeedTabContent<Route: Hashable>: View {
    @ObservedObject var viewModel: TVShowFeedViewModel
    let feedType: TVShowFeedType
    let detailRouteBuilder: (TVShow) -> Route

    var body: some View {
        let shows = viewModel.shows(for: feedType)
        let isLoading = viewModel.isLoading(for: feedType)

        FeedStateView(
            phase: phase(shows: shows, isLoading: isLoading),
            isRefreshing: isLoading,
            retryAction: { viewModel.loadFeed(feedType) }
        ) {
            FeedItemsView(
                items: shows.map { $0.feedItem(route: detailRouteBuilder($0)) },
                accessibilityIdentifier: "tvshows_list_items",
                onItemAppear: { item in
                    viewModel.fetchMoreContentIfNeeded(currentShowId: item.id)
                }
            )
        }
        .accessibilityIdentifier("tvshows_list_content")
        .refreshable {
            await viewModel.refresh(feedType)
        }
        .onAppear {
            viewModel.loadFeed(feedType)
        }
    }

    private func phase(shows: [TVShow], isLoading: Bool) -> FeedLoadPhase {
        if isLoading, shows.isEmpty {
            return .loading
        }
        if let message = viewModel.errorMessage(for: feedType), shows.isEmpty {
            return .error(message: message)
        }
        return shows.isEmpty ? .empty : .loaded
    }
}

extension TVShow {
    func feedItem<Route: Hashable>(route: Route) -> FeedItem<Route> {
        FeedItem(
            id: id,
            entity: toMovieRowEntity(),
            route: route,
            accessibilityIdentifier: "tvshowlist1.tvshowrow\(id)"
        )
    }
}
