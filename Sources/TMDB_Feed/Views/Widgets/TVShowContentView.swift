import CoreFeatures
import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend

// MARK: - TV Show Content View

@available(iOS 16, macOS 10.15, *)
struct TVShowContentView<Route: Hashable>: View {
    @ObservedObject var viewModel: TVShowFeedViewModel
    let detailRouteBuilder: (TVShow) -> Route
    @Binding var useFancyDesign: Bool

    var body: some View {
        Group {
            switch viewModel.state {
            case .initial:
                EmptyView()
            case .loading where viewModel.searchQuery.isEmpty:
                loadingView
            case .error(let message):
                errorView(message)
            case .loaded(let shows), .searchResults(let shows):
                loadedContentView(shows)
            case .loading:
                loadingWithContent
            }
        }
    }

    // MARK: - ViewBuilder Functions

    @ViewBuilder
    private var loadingView: some View {
        Text("Loading...")
    }

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        Text(message)
    }

    @ViewBuilder
    private func loadedContentView(_ shows: [TVShow]) -> some View {
        VStack(spacing: 0) {
            // Show filter chips when searching
            if !viewModel.searchQuery.isEmpty {
                filterChipsView
            }
            if shows.isEmpty {
                CommonNoResultView(useFancyDesign: $useFancyDesign)
            } else {
                showsListView(shows)
            }
        }
    }

    @ViewBuilder
    private var filterChipsView: some View {
        FilterChipsView(
            filters: $viewModel.searchFilters,
            onFilterTap: { filterType in
                viewModel.updateSelectedFilterToShow(filterType)
            }
        )
    }

    @ViewBuilder
    private func showsListView(_ shows: [TVShow]) -> some View {
        List(shows) { show in
            NavigationTVShowRow<Route>(viewModel: viewModel, show: show, routeBuilder: detailRouteBuilder)
        }
        .accessibilityIdentifier("tvshows_list_content")
        .searchable(text: $viewModel.searchQuery)
        .overlay {
            if case .loading = viewModel.state {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color.black.opacity(0.1))
            }
        }
    }

    @ViewBuilder
    private var loadingWithContent: some View {
        VStack(spacing: 0) {
            // Show filter chips when searching
            if !viewModel.searchQuery.isEmpty {
                filterChipsView
            }

            List([] as [TVShow]) { show in
                NavigationTVShowRow<Route>(viewModel: viewModel, show: show, routeBuilder: detailRouteBuilder)
            }
            .searchable(text: $viewModel.searchQuery)
            .overlay {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color.black.opacity(0.1))
            }
        }
    }
}
