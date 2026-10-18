import Shared_UI_Support
import SwiftUI
import TMDB_Shared_UI

@available(iOS 16, *)
struct MovieFeedContent<Route: Hashable>: View {
    @ObservedObject var viewModel: MovieFeedViewModel
    let detailRouteBuilder: (Movie) -> Route

    var body: some View {
        FeedStateView(state: viewModel.state, retryAction: { viewModel.load() }, content: { movies in
            FeedItemsView(
                items: movies.map { $0.feedItem(route: detailRouteBuilder($0)) },
                accessibilityIdentifier: "movies_list_items",
                onItemAppear: { item in
                    viewModel.fetchMoreContentIfNeeded(currentMovieId: item.id)
                }
            )
        })
        .accessibilityIdentifier("movies_list_content")
        .refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            viewModel.load()
        }
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

#if DEBUG
#Preview("Loaded") {
    TMDBFeedPreviewCatalog.movieContentLoaded.view
}

#Preview("Offline") {
    TMDBFeedPreviewCatalog.movieContentOffline.view
}
#endif
