import Shared_UI_Support
import SwiftUI

// MARK: - Movie Content View

@available(iOS 16, macOS 10.15, *)
struct MovieContentView<Route: Hashable>: View {
    @ObservedObject var viewModel: MovieFeedViewModel
    let detailRouteBuilder: (Movie) -> Route
    @Binding var useFancyDesign: Bool

    var body: some View {
        Group {
            switch viewModel.state {
            case .initial:
                EmptyView()
            case .loading where viewModel.searchQuery.isEmpty:
                ProgressView(L10n.playingLoading)
            case .error(let message):
                Text(message)
            case .loaded(let movies), .searchResults(let movies):
                VStack(spacing: 0) {
                    // Show filter chips when searching
                    if !viewModel.searchQuery.isEmpty {
                        FilterChipsView(
                            filters: $viewModel.searchFilters,
                            onFilterTap: { filterType in
                                viewModel.updateSelectedFilterToShow(filterType)
                            }
                        )
                    }
                    if movies.isEmpty {
                        CommonNoResultView(useFancyDesign: $useFancyDesign)
                    } else {
                        List(movies) { movie in
                            NavigationMovieRow(viewModel, movie: movie, routeBuilder: detailRouteBuilder)
                        }
                        .searchable(text: $viewModel.searchQuery)
                        .overlay {
                            if case .loading = viewModel.state {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    .background(Color.black.opacity(0.1))
                            }
                        }
                    }
                }
            case .loading:
                VStack(spacing: 0) {
                    // Show filter chips when searching
                    if !viewModel.searchQuery.isEmpty {
                        FilterChipsView(
                            filters: $viewModel.searchFilters,
                            onFilterTap: { filterType in
                                viewModel.updateSelectedFilterToShow(filterType)
                            }
                        )
                    }

                    List([] as [Movie]) { movie in
                        NavigationMovieRow(viewModel, movie: movie, routeBuilder: detailRouteBuilder)
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
    }
}
