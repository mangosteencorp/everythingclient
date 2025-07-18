import Combine
import CoreFeatures
import Foundation
import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16, macOS 10.15, *)
public struct MovieFeedListPage<Route: Hashable>: View {
    @StateObject var movieViewModel: MovieFeedViewModel
    @StateObject var tvShowViewModel: TVShowFeedViewModel
    @State private var selectedContentType: ContentFeedType = .movies
    let detailRouteBuilder: (Movie) -> Route
    let tvShowDetailRouteBuilder: (TVShow) -> Route
    private var cancellables = Set<AnyCancellable>()
    @State private var useFancyDesign: Bool = true

    public init(
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        detailRouteBuilder: @escaping (Movie) -> Route,
        tvShowDetailRouteBuilder: @escaping (TVShow) -> Route
    ) {
        _movieViewModel = StateObject(wrappedValue: MovieFeedViewModel(
            apiService: apiService,
            additionalParams: additionalParams,
            analyticsTracker: analyticsTracker
        ))
        _tvShowViewModel = StateObject(wrappedValue: TVShowFeedViewModel(
            apiService: apiService,
            additionalParams: additionalParams,
            analyticsTracker: analyticsTracker
        ))
        self.detailRouteBuilder = detailRouteBuilder
        self.tvShowDetailRouteBuilder = tvShowDetailRouteBuilder
    }

#if DEBUG
    init(
        movieViewModel: MovieFeedViewModel,
        tvShowViewModel: TVShowFeedViewModel,
        detailRouteBuilder: @escaping (Movie) -> Route,
        tvShowDetailRouteBuilder: @escaping (TVShow) -> Route
    ) {
        _movieViewModel = StateObject(wrappedValue: movieViewModel)
        _tvShowViewModel = StateObject(wrappedValue: tvShowViewModel)
        self.detailRouteBuilder = detailRouteBuilder
        self.tvShowDetailRouteBuilder = tvShowDetailRouteBuilder
    }
#endif

    public var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            Picker("Content Type", selection: $selectedContentType) {
                ForEach(ContentFeedType.allCases) { contentType in
                    Text(contentType.localizedTitle).tag(contentType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 8)

            // Content based on selected type
            Group {
                switch selectedContentType {
                case .movies:
                    MovieContentView(
                        viewModel: movieViewModel,
                        detailRouteBuilder: detailRouteBuilder,
                        useFancyDesign: $useFancyDesign
                    )
                case .tvShows:
                    TVShowContentView(
                        viewModel: tvShowViewModel,
                        detailRouteBuilder: tvShowDetailRouteBuilder,
                        useFancyDesign: $useFancyDesign
                    )
                }
            }
        }
        .accessibilityIdentifier("movielist1.group")
        .navigationTitle(currentFeedTypeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    switch selectedContentType {
                    case .movies:
                        ForEach(MovieFeedType.allCases) { feedType in
                            Button(action: {
                                movieViewModel.switchFeedType(feedType)
                            }) {
                                HStack {
                                    Text(feedType.localizedTitle)
                                    if movieViewModel.currentFeedType == feedType {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    case .tvShows:
                        ForEach(TVShowFeedType.allCases) { feedType in
                            Button(action: {
                                tvShowViewModel.switchFeedType(feedType)
                            }) {
                                HStack {
                                    Text(feedType.localizedTitle)
                                    if tvShowViewModel.currentFeedType == feedType {
                                        Image(systemName: "checkmark")
                                    }
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
        .sheet(isPresented: Binding(
            get: { currentViewModel.showingFilterSheet },
            set: { newValue in
                switch selectedContentType {
                case .movies:
                    movieViewModel.showingFilterSheet = newValue
                case .tvShows:
                    tvShowViewModel.showingFilterSheet = newValue
                }
            }
        )) {
            if let filterType = currentViewModel.selectedFilterType {
                FilterConfigurationView(
                    filters: currentViewModel.searchFiltersBinding,
                    filterType: filterType
                )
            }
        }
        .onFirstAppear {
            loadInitialContent()
        }
        .onChange(of: selectedContentType) { _ in
            loadInitialContent()
        }
    }

    private var currentViewModel: (showingFilterSheet: Bool, selectedFilterType: FilterType?, searchFiltersBinding: Binding<SearchFilters>) {
        switch selectedContentType {
        case .movies:
            return (
                showingFilterSheet: movieViewModel.showingFilterSheet,
                selectedFilterType: movieViewModel.selectedFilterType,
                searchFiltersBinding: movieViewModel.searchFiltersBinding
            )
        case .tvShows:
            return (
                showingFilterSheet: tvShowViewModel.showingFilterSheet,
                selectedFilterType: tvShowViewModel.selectedFilterType,
                searchFiltersBinding: tvShowViewModel.searchFiltersBinding
            )
        }
    }

    private var currentFeedTypeTitle: String {
        switch selectedContentType {
        case .movies:
            return movieViewModel.currentFeedType.localizedTitle
        case .tvShows:
            return tvShowViewModel.currentFeedType.localizedTitle
        }
    }

    private func loadInitialContent() {
        switch selectedContentType {
        case .movies:
            // Only fetch if we don't have any movies loaded for the current feed type
            if case .initial = movieViewModel.state {
                movieViewModel.fetchNowPlayingMovies()
            } else if !movieViewModel.hasCachedMovies {
                // If we have no cached data, fetch it
                movieViewModel.fetchNowPlayingMovies()
            } else {
                // If we have data but it's not for the current feed type, load the cached data
                movieViewModel.loadCurrentFeedMovies()
            }
        case .tvShows:
            // Always fetch TV shows if we're in initial state or if we don't have any shows loaded
            if case .initial = tvShowViewModel.state {
                tvShowViewModel.fetchAiringTodayTVShows()
            } else if !tvShowViewModel.hasCachedShows {
                // If we have no cached data, fetch it
                tvShowViewModel.fetchAiringTodayTVShows()
            } else {
                // If we have data but it's not for the current feed type, load the cached data
                tvShowViewModel.loadCurrentFeedTVShows()
            }
        }
    }
}

// MARK: - TV Show Row Entity

extension TVShow {
    func toMovieRowEntity() -> MovieRowEntity {
        return MovieRowEntity(
            id: id,
            posterPath: poster_path,
            title: name,
            voteAverage: Double(vote_average),
            releaseDate: nil, // TV shows don't have release dates like movies
            overview: overview
        )
    }
}

// MARK: - Extensions for View Models

extension MovieFeedViewModel {
    var searchFiltersBinding: Binding<SearchFilters> {
        Binding(
            get: { self.searchFilters },
            set: { self.searchFilters = $0 }
        )
    }
}

extension TVShowFeedViewModel {
    var searchFiltersBinding: Binding<SearchFilters> {
        Binding(
            get: { self.searchFilters },
            set: { self.searchFilters = $0 }
        )
    }
}

#if DEBUG
// swiftlint:disable all
@available(iOS 16, macOS 10.15, *)
#Preview {
    MovieFeedListPage(
        apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
        detailRouteBuilder: { _ in 1 },
        tvShowDetailRouteBuilder: { _ in 2 }
    )
}

@available(iOS 16, macOS 10.15, *)
struct MovieFeedListPage_Previews : PreviewProvider {
    static var previews: some View {
        let movieViewModel = MovieFeedViewModel.init(apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))
        let tvShowViewModel = TVShowFeedViewModel.init(apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            movieViewModel.state = .searchResults([])
            tvShowViewModel.state = .searchResults([])
        }

        return NavigationView {
            MovieFeedListPage(
                movieViewModel: movieViewModel,
                tvShowViewModel: tvShowViewModel,
                detailRouteBuilder: { _ in 1 },
                tvShowDetailRouteBuilder: { _ in 2 }
            )
        }
    }
}

// swiftlint:enable all
#endif
