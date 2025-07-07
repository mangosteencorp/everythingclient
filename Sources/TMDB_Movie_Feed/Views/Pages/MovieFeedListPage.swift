import Combine
import CoreFeatures
import Foundation
import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI
@available(iOS 16, macOS 10.15, *)
public struct MovieFeedListPage<Route: Hashable>: View {
    @StateObject var viewModel: MovieFeedViewModel
    let detailRouteBuilder: (Movie) -> Route
    private var cancellables = Set<AnyCancellable>()
    @State private var useFancyDesign: Bool = true
    public init(
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        detailRouteBuilder: @escaping (Movie) -> Route
    ) {
        _viewModel = StateObject(wrappedValue: MovieFeedViewModel(
            apiService: apiService,
            additionalParams: additionalParams,
            analyticsTracker: analyticsTracker
        ))
        self.detailRouteBuilder = detailRouteBuilder
    }

#if DEBUG
    init(
        viewModel: MovieFeedViewModel,
        detailRouteBuilder: @escaping (Movie) -> Route
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.detailRouteBuilder = detailRouteBuilder
    }
#endif

    public var body: some View {
        VStack(spacing: 0) {
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
                            CommonNoResultView(useFancyDesign: $useFancyDesign).toolbar {
                                SwitchDesignToolbarItem(action: {
                                    useFancyDesign.toggle()
                                })
                            }
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
        .accessibilityIdentifier("movielist1.group")
        .navigationTitle(viewModel.currentFeedType.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(MovieFeedType.allCases) { feedType in
                        Button(action: {
                            viewModel.switchFeedType(feedType)
                        }) {
                            HStack {
                                Text(feedType.localizedTitle)
                                if viewModel.currentFeedType == feedType {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "chevron.up.chevron.down.square")
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingFilterSheet) {
            if let filterType = viewModel.selectedFilterType {
                FilterConfigurationView(
                    filters: $viewModel.searchFilters,
                    filterType: filterType
                )
            }
        }
        .onFirstAppear {
            viewModel.fetchNowPlayingMovies()
        }
    }
}

#if DEBUG
// swiftlint:disable all
@available(iOS 16, macOS 10.15, *)
#Preview {
    MovieFeedListPage(apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
                      detailRouteBuilder: { _ in 1 })
}

@available(iOS 16, macOS 10.15, *)
struct MovieFeedListPage_Previews : PreviewProvider {
    static var previews: some View {
        let viewModel = MovieFeedViewModel.init(apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            viewModel.state = .searchResults([])
        }
        return NavigationView {
            MovieFeedListPage(viewModel: viewModel,
                              detailRouteBuilder: { _ in 1 })
        }
    }
}

// swiftlint:enable all
#endif
