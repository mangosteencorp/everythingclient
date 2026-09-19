import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// The one search screen in the app.
///
/// Covers all seven TMDB search endpoints through a single scope picker and renders every scope
/// as the same paginated list. Routing is the host's business: `routeBuilder` returns `nil` for
/// kinds this app has no page for (collections, companies, keywords), and those rows simply do
/// not push.
@available(iOS 16, *)
public struct SearchPage<Route: Hashable>: View {
    @StateObject private var viewModel: SearchViewModel
    private let routeBuilder: (SearchResultItem) -> Route?

    public init(
        service: TMDBSearchServicing,
        routeBuilder: @escaping (SearchResultItem) -> Route?
    ) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(service: service))
        self.routeBuilder = routeBuilder
    }

#if DEBUG
    init(
        viewModel: SearchViewModel,
        routeBuilder: @escaping (SearchResultItem) -> Route?
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.routeBuilder = routeBuilder
    }
#endif

    public var body: some View {
        VStack(spacing: 0) {
            // Kept outside the results so that a scope or filter change never relayouts the
            // chips — they sit above whatever the list is doing.
            if !viewModel.availableFilters.isEmpty {
                FilterChipsView(
                    filters: $viewModel.filters,
                    types: viewModel.availableFilters,
                    onFilterTap: { viewModel.selectFilter($0) }
                )
            }

            results
        }
        .navigationTitle(L10n.feedSearch)
        .searchable(text: $viewModel.query, prompt: L10n.searchPrompt)
        .searchScopes($viewModel.scope) {
            ForEach(SearchScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .sheet(isPresented: $viewModel.showingFilterSheet) {
            if let filterType = viewModel.selectedFilterType {
                FilterConfigurationView(filters: $viewModel.filters, filterType: filterType)
            }
        }
        .accessibilityIdentifier("feed_search_page")
    }

    @ViewBuilder
    private var results: some View {
        FeedStateView(
            phase: phase,
            // A scope switch keeps the previous rows and dims them rather than tearing the list
            // down for a spinner and building a new one — that teardown is what made switching
            // scopes after a search jump around.
            isRefreshing: viewModel.isReloading,
            allowsCancel: true,
            retryAction: { viewModel.retry() },
            cancelAction: { viewModel.clear() },
            content: {
                ScrollViewReader { proxy in
                    List(viewModel.items) { item in
                        row(for: item)
                            .onAppear { viewModel.loadMoreIfNeeded(currentItem: item) }
                    }
                    .listStyle(.plain)
                    // Rows from two different scopes share no identity, so letting SwiftUI
                    // animate the diff is a full-list churn rather than a transition.
                    .animation(nil, value: viewModel.items)
                    .onChange(of: viewModel.resultsGeneration) { _ in
                        // Land at the top of the new results instead of wherever the previous
                        // scope happened to be scrolled to.
                        guard let first = viewModel.items.first else { return }
                        proxy.scrollTo(first.id, anchor: .top)
                    }
                    .accessibilityIdentifier("search_results")
                }
            }
        )
    }

    @ViewBuilder
    private func row(for item: SearchResultItem) -> some View {
        if let route = routeBuilder(item) {
            NavigationLink(value: route) {
                SearchResultRow(item: item)
            }
            .accessibilityIdentifier("search_result_\(item.id)")
        } else {
            SearchResultRow(item: item)
                .accessibilityIdentifier("search_result_\(item.id)")
        }
    }

    private var phase: FeedLoadPhase {
        // `isReloading` deliberately does not appear here: it renders as an overlay on the
        // results that are already up, not as a different phase.
        if viewModel.isLoadingFirstPage {
            return .loading
        }
        if let message = viewModel.errorMessage {
            return .error(message: message)
        }
        if !viewModel.hasSearched {
            return .placeholder(systemImage: "magnifyingglass", title: L10n.feedSearch)
        }
        return viewModel.items.isEmpty ? .empty : .loaded
    }
}

@available(iOS 16, *)
struct SearchResultRow: View {
    let item: SearchResultItem

    var body: some View {
        HStack(spacing: 12) {
            artwork
                .frame(width: PosterSize.thumbnail.width, height: PosterSize.thumbnail.height)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .lineLimit(2)
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if let voteAverage = item.voteAverage, voteAverage > 0 {
                PopularityBadge(score: Int(voteAverage * 10))
            }
        }
        .padding(.vertical, 2)
        // Keywords carry one line and movies carry three; without a floor the list height
        // changes with every scope switch.
        .frame(minHeight: PosterSize.thumbnail.height)
    }

    @ViewBuilder
    private var artwork: some View {
        if let imagePath = item.imagePath {
            RemoteTMDBImage(posterPath: imagePath, imageSize: .posterSmall)
        } else {
            // Keywords and most companies have no artwork at all.
            Image(systemName: item.kind.systemImage)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
        }
    }
}
