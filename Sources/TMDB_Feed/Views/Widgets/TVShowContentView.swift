import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16, *)
struct TVShowFeedContent<Route: Hashable>: View {
    @ObservedObject var viewModel: TVShowFeedViewModel
    let detailRouteBuilder: (TVShow) -> Route

    var body: some View {
        FeedStateView(state: viewModel.state, retryAction: { viewModel.load() }, content: { shows in
            FeedItemsView(
                items: shows.map { $0.feedItem(route: detailRouteBuilder($0)) },
                accessibilityIdentifier: "tvshows_list_items",
                onItemAppear: { item in
                    viewModel.fetchMoreContentIfNeeded(currentShowId: item.id)
                }
            )
        })
        .accessibilityIdentifier("tvshows_list_content")
        .refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            viewModel.load()
        }
    }
}

extension TVShow {
    func toMovieRowEntity() -> MovieRowEntity {
        MovieRowEntity(
            id: id,
            posterPath: poster_path,
            title: name,
            voteAverage: Double(vote_average),
            releaseDate: nil,
            overview: overview
        )
    }

    func feedItem<Route: Hashable>(route: Route) -> FeedItem<Route> {
        FeedItem(
            id: id,
            entity: toMovieRowEntity(),
            route: route,
            accessibilityIdentifier: "tvshowlist1.tvshowrow\(id)"
        )
    }
}

#if DEBUG
#Preview {
    TMDBFeedPreviewCatalog.tvShowContent.view
}
#endif
