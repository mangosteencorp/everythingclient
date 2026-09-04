import CoreFeatures
import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16, *)
struct FeedSearchTabContent<Route: Hashable>: View {
    @ObservedObject var movieViewModel: MovieFeedViewModel
    @ObservedObject var tvShowViewModel: TVShowFeedViewModel
    let detailRouteBuilder: (Movie) -> Route
    let tvShowDetailRouteBuilder: (TVShow) -> Route
    @State private var searchContentType: ContentFeedType = .movies

    private var activeSearchQuery: Binding<String> {
        switch searchContentType {
        case .movies: return $movieViewModel.searchQuery
        case .tvShows: return $tvShowViewModel.searchQuery
        }
    }

    private var activeSearchFilters: Binding<SearchFilters> {
        switch searchContentType {
        case .movies: return movieViewModel.searchFiltersBinding
        case .tvShows: return tvShowViewModel.searchFiltersBinding
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Search Type", selection: $searchContentType) {
                ForEach(ContentFeedType.allCases) { contentType in
                    Text(contentType.localizedTitle).tag(contentType)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .accessibilityIdentifier("search_content_type_picker")
            .onChange(of: searchContentType) { _ in
                movieViewModel.cancelSearch()
                tvShowViewModel.cancelSearch()
            }

            FeedSearchBar(
                text: activeSearchQuery,
                prompt: searchContentType == .movies ? L10n.feedSearchMovies : L10n.feedSearchTv
            )
            .padding(.horizontal)
            .padding(.vertical, 8)

            FilterChipsView(
                filters: activeSearchFilters,
                onFilterTap: { filterType in
                    switch searchContentType {
                    case .movies:
                        movieViewModel.updateSelectedFilterToShow(filterType)
                    case .tvShows:
                        tvShowViewModel.updateSelectedFilterToShow(filterType)
                    }
                }
            )

            searchBody
        }
        .accessibilityIdentifier("feed_search_tab")
        .sheet(isPresented: searchSheetBinding) {
            if let filterType = selectedFilterType {
                FilterConfigurationView(
                    filters: activeSearchFilters,
                    filterType: filterType
                )
            }
        }
    }

    @ViewBuilder
    private var searchBody: some View {
        switch searchContentType {
        case .movies:
            MovieSearchResultsContent(
                viewModel: movieViewModel,
                detailRouteBuilder: detailRouteBuilder
            )
        case .tvShows:
            TVShowSearchResultsContent(
                viewModel: tvShowViewModel,
                detailRouteBuilder: tvShowDetailRouteBuilder
            )
        }
    }

    private var searchSheetBinding: Binding<Bool> {
        switch searchContentType {
        case .movies:
            return $movieViewModel.showingFilterSheet
        case .tvShows:
            return $tvShowViewModel.showingFilterSheet
        }
    }

    private var selectedFilterType: FilterType? {
        switch searchContentType {
        case .movies: return movieViewModel.selectedFilterType
        case .tvShows: return tvShowViewModel.selectedFilterType
        }
    }
}

@available(iOS 16, *)
private struct FeedSearchBar: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(prompt, text: $text)
                .platformDisableAutocapitalization()
                .disableAutocorrection(true)
                .accessibilityIdentifier("feed_search_field")

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("feed_search_clear")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.platformSecondaryBackground)
        )
        .accessibilityIdentifier("feed_search_bar")
    }
}

@available(iOS 16, *)
private struct MovieSearchResultsContent<Route: Hashable>: View {
    @ObservedObject var viewModel: MovieFeedViewModel
    let detailRouteBuilder: (Movie) -> Route

    var body: some View {
        FeedStateView(
            phase: phase,
            allowsCancel: true,
            retryAction: { viewModel.retrySearch() },
            cancelAction: { viewModel.cancelSearch() }
        ) {
            FeedItemsView(
                items: results.map { $0.feedItem(route: detailRouteBuilder($0)) },
                accessibilityIdentifier: "movies_search_results",
                onItemAppear: { item in
                    viewModel.fetchMoreContentIfNeeded(currentMovieId: item.id)
                }
            )
        }
        .refreshable {
            guard !viewModel.searchQuery.isEmpty else { return }
            viewModel.retrySearch()
        }
    }

    private var results: [Movie] {
        switch viewModel.state {
        case let .loaded(movies), let .searchResults(movies): return movies
        case .initial, .loading, .error: return []
        }
    }

    private var phase: FeedLoadPhase {
        switch viewModel.state {
        case .initial:
            return .placeholder(systemImage: "magnifyingglass", title: L10n.feedSearch)
        case .loading:
            return .loading
        case let .error(message):
            return .error(message: message)
        case .loaded, .searchResults:
            return results.isEmpty ? .empty : .loaded
        }
    }
}

@available(iOS 16, *)
private struct TVShowSearchResultsContent<Route: Hashable>: View {
    @ObservedObject var viewModel: TVShowFeedViewModel
    let detailRouteBuilder: (TVShow) -> Route

    var body: some View {
        FeedStateView(
            phase: phase,
            allowsCancel: true,
            retryAction: { viewModel.retrySearch() },
            cancelAction: { viewModel.cancelSearch() }
        ) {
            FeedItemsView(
                items: results.map { $0.feedItem(route: detailRouteBuilder($0)) },
                accessibilityIdentifier: "tvshows_search_results",
                onItemAppear: { item in
                    viewModel.fetchMoreContentIfNeeded(currentShowId: item.id)
                }
            )
        }
        .refreshable {
            guard !viewModel.searchQuery.isEmpty else { return }
            viewModel.retrySearch()
        }
    }

    private var results: [TVShow] {
        switch viewModel.state {
        case let .loaded(shows), let .searchResults(shows): return shows
        case .initial, .loading, .error: return []
        }
    }

    private var phase: FeedLoadPhase {
        switch viewModel.state {
        case .initial:
            return .placeholder(systemImage: "magnifyingglass", title: L10n.feedSearch)
        case .loading:
            return .loading
        case let .error(message):
            return .error(message: message)
        case .loaded, .searchResults:
            return results.isEmpty ? .empty : .loaded
        }
    }
}

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
