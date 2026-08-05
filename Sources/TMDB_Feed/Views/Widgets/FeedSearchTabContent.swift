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
                .textInputAutocapitalization(.never)
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
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityIdentifier("feed_search_bar")
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
        .refreshable {
            guard !viewModel.searchQuery.isEmpty else { return }
            viewModel.retrySearch()
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
        .refreshable {
            guard !viewModel.searchQuery.isEmpty else { return }
            viewModel.retrySearch()
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
