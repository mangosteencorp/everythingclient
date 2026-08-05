import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16, *)
struct TVShowFeedTabContent<Route: Hashable>: View {
    @ObservedObject var viewModel: TVShowFeedViewModel
    let feedType: TVShowFeedType
    let detailRouteBuilder: (TVShow) -> Route
    @Binding var useFancyDesign: Bool

    var body: some View {
        let shows = viewModel.shows(for: feedType)
        Group {
            if viewModel.isLoading(for: feedType), shows.isEmpty {
                ProgressView(L10n.playingLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage(for: feedType), shows.isEmpty {
                FeedErrorContentView(
                    message: message,
                    allowsCancelSearch: false,
                    retryAction: { viewModel.loadFeed(feedType) },
                    cancelAction: nil
                )
            } else if shows.isEmpty {
                CommonNoResultView(
                    configuration: NoResultViewConfiguration(
                        primaryButtonAction: { [weak viewModel] in
                            viewModel?.loadFeed(feedType)
                        }
                    ),
                    useFancyDesign: $useFancyDesign
                )
            } else {
                List(shows) { show in
                    NavigationTVShowRow(viewModel: viewModel, show: show, routeBuilder: detailRouteBuilder)
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
        .accessibilityIdentifier("tvshows_list_content")
        .refreshable {
            await viewModel.refresh(feedType)
        }
        .onFirstAppear {
            viewModel.loadFeed(feedType)
        }
    }
}
