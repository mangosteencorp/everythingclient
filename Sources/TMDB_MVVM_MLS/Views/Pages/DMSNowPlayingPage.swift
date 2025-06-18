import Combine
import CoreFeatures
import Foundation
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI
@available(iOS 16, macOS 10.15, *)
public struct MovieFeedListPage<Route: Hashable>: View {
    @StateObject var viewModel: MovieFeedViewModel
    @State private var showingFilterSheet = false
    @State private var selectedFilterType: FilterType?
    let detailRouteBuilder: (Movie) -> Route

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
                case .loading:
                    ProgressView("Loading...")
                case .error(let message):
                    Text(message)
                case .loaded(let movies), .searchResults(let movies):
                    VStack(spacing: 0) {
                        // Filter chips - only show when searching
                        if !viewModel.searchQuery.isEmpty {
                            FilterChipsView(
                                filters: $viewModel.searchFilters,
                                onFilterTap: { filterType in
                                    selectedFilterType = filterType
                                    showingFilterSheet = true
                                }
                            )
                        }

                        List(movies) { movie in
                            NavigationMovieRow(viewModel, movie: movie, routeBuilder: detailRouteBuilder)
                        }
                        .searchable(text: $viewModel.searchQuery)
                    }
                }
            }
        }
        .accessibilityIdentifier("movielist1.group")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("", selection: $viewModel.feedType) {
                    ForEach(MovieFeedType.allCases) { type in
                        Text(type.localizedTitle).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFilterSheet) {
            if let filterType = selectedFilterType {
                FilterConfigurationView(
                    filters: $viewModel.searchFilters,
                    filterType: filterType
                )
            }
        }
        .onAppear {
            viewModel.fetchMovies()
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
#Preview("now playing page within nested tab view") {
    TabView {
        TabView {
            NavigationStack {
                MovieFeedListPage(
                    apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
                    detailRouteBuilder: { _ in 1 }
                )
                .tag(0)
                .tabItem {
                    Label("First View", systemImage: "house")
                }
            }
            Text("Second View").tag(1)
                .tabItem {
                    Label("Second View", systemImage: "gear")
                }
        }
        //.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .tag(0)
        .tabItem {
            Label("Outer First View", systemImage: "star")
        }
        Text("Outer Second View").tag(1)
            .tabItem {
                Label("Outer Second View", systemImage: "moon")
            }
    }
}
// swiftlint:enable all
#endif
