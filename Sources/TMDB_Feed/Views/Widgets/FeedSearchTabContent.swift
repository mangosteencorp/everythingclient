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
    @Binding var useFancyDesign: Bool
    @State private var searchContentType: ContentFeedType = .movies

    var body: some View {
        VStack(spacing: 0) {
            Picker("Search Type", selection: $searchContentType) {
                ForEach(ContentFeedType.allCases) { contentType in
                    Text(contentType.localizedTitle).tag(contentType)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .accessibilityIdentifier("search_content_type_picker")
            .onChange(of: searchContentType) { _ in
                activeViewModelCancelIfNeeded()
            }

            searchBody
        }
        .accessibilityIdentifier("feed_search_tab")
    }

    @ViewBuilder
    private var searchBody: some View {
        switch searchContentType {
        case .movies:
            MovieSearchResultsContent(
                viewModel: movieViewModel,
                detailRouteBuilder: detailRouteBuilder,
                useFancyDesign: $useFancyDesign
            )
        case .tvShows:
            TVShowSearchResultsContent(
                viewModel: tvShowViewModel,
                detailRouteBuilder: tvShowDetailRouteBuilder,
                useFancyDesign: $useFancyDesign
            )
        }
    }

    private func activeViewModelCancelIfNeeded() {
        movieViewModel.cancelSearch()
        tvShowViewModel.cancelSearch()
    }
}

@available(iOS 16, *)
private struct MovieSearchResultsContent<Route: Hashable>: View {
    @ObservedObject var viewModel: MovieFeedViewModel
    let detailRouteBuilder: (Movie) -> Route
    @Binding var useFancyDesign: Bool

    var body: some View {
        Group {
            switch viewModel.state {
            case .initial:
                ContentUnavailablePlaceholder(systemImage: "magnifyingglass", title: L10n.feedSearch)
            case .loading:
                ProgressView(L10n.playingLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                FeedErrorContentView(
                    message: message,
                    allowsCancelSearch: true,
                    retryAction: { viewModel.retrySearch() },
                    cancelAction: { viewModel.cancelSearch() }
                )
            case .loaded(let movies), .searchResults(let movies):
                VStack(spacing: 0) {
                    if !viewModel.searchQuery.isEmpty {
                        FilterChipsView(
                            filters: $viewModel.searchFilters,
                            onFilterTap: { filterType in
                                viewModel.updateSelectedFilterToShow(filterType)
                            }
                        )
                    }
                    if movies.isEmpty {
                        CommonNoResultView(
                            configuration: NoResultViewConfiguration(
                                primaryButtonAction: { [weak viewModel] in
                                    viewModel?.retrySearch()
                                },
                                secondaryButtonAction: { [weak viewModel] in
                                    viewModel?.cancelSearch()
                                }
                            ),
                            useFancyDesign: $useFancyDesign
                        )
                    } else {
                        List(movies) { movie in
                            NavigationMovieRow(viewModel, movie: movie, routeBuilder: detailRouteBuilder)
                        }
                        .accessibilityIdentifier("movies_search_results")
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: L10n.feedSearchMovies)
        .refreshable {
            guard !viewModel.searchQuery.isEmpty else { return }
            viewModel.retrySearch()
        }
        .sheet(isPresented: $viewModel.showingFilterSheet) {
            if let filterType = viewModel.selectedFilterType {
                FilterConfigurationView(
                    filters: viewModel.searchFiltersBinding,
                    filterType: filterType
                )
            }
        }
    }
}

@available(iOS 16, *)
private struct TVShowSearchResultsContent<Route: Hashable>: View {
    @ObservedObject var viewModel: TVShowFeedViewModel
    let detailRouteBuilder: (TVShow) -> Route
    @Binding var useFancyDesign: Bool

    var body: some View {
        Group {
            switch viewModel.state {
            case .initial:
                ContentUnavailablePlaceholder(systemImage: "magnifyingglass", title: L10n.feedSearch)
            case .loading:
                ProgressView(L10n.playingLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                FeedErrorContentView(
                    message: message,
                    allowsCancelSearch: true,
                    retryAction: { viewModel.retrySearch() },
                    cancelAction: { viewModel.cancelSearch() }
                )
            case .loaded(let shows), .searchResults(let shows):
                VStack(spacing: 0) {
                    if !viewModel.searchQuery.isEmpty {
                        FilterChipsView(
                            filters: $viewModel.searchFilters,
                            onFilterTap: { filterType in
                                viewModel.updateSelectedFilterToShow(filterType)
                            }
                        )
                    }
                    if shows.isEmpty {
                        CommonNoResultView(
                            configuration: NoResultViewConfiguration(
                                primaryButtonAction: { [weak viewModel] in
                                    viewModel?.retrySearch()
                                },
                                secondaryButtonAction: { [weak viewModel] in
                                    viewModel?.cancelSearch()
                                }
                            ),
                            useFancyDesign: $useFancyDesign
                        )
                    } else {
                        List(shows) { show in
                            NavigationTVShowRow(viewModel: viewModel, show: show, routeBuilder: detailRouteBuilder)
                        }
                        .accessibilityIdentifier("tvshows_search_results")
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: L10n.feedSearchTv)
        .refreshable {
            guard !viewModel.searchQuery.isEmpty else { return }
            viewModel.retrySearch()
        }
        .sheet(isPresented: $viewModel.showingFilterSheet) {
            if let filterType = viewModel.selectedFilterType {
                FilterConfigurationView(
                    filters: viewModel.searchFiltersBinding,
                    filterType: filterType
                )
            }
        }
    }
}

private struct ContentUnavailablePlaceholder: View {
    let systemImage: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("feed_search_placeholder")
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
