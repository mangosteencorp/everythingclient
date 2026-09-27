import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// The one search screen in the app.
///
/// Covers all seven TMDB search endpoints through a single scope picker and renders every scope
/// as the same paginated list. Before anything is typed it offers recent searches and today's
/// trending titles. Routing is the host's business: `routeBuilder` returns `nil` for kinds this
/// app has no page for (collections, companies, keywords), and those rows simply do not push.
@available(iOS 16, *)
public struct SearchPage<Route: Hashable>: View {
    @StateObject private var viewModel: SearchViewModel
    private let routeBuilder: (SearchResultItem) -> Route?

    @Environment(\.searchPageFieldPlacement) private var fieldPlacement

    public init(
        service: TMDBSearchServicing,
        recentsStore: RecentSearchesStoring = UserDefaultsRecentSearchesStore(),
        routeBuilder: @escaping (SearchResultItem) -> Route?
    ) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(service: service, recentsStore: recentsStore))
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
            // header — it sits above whatever the list is doing, and stays put while it scrolls.
            header

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(L10n.feedSearch)
        .searchable(text: $viewModel.query, placement: fieldPlacement, prompt: L10n.searchPrompt)
        .onSubmit(of: .search) { viewModel.saveRecentSearch() }
        // Leaving with results on screen — opening one, or switching tabs — counts as having
        // used that query, the same as submitting it.
        .onDisappear {
            guard !viewModel.items.isEmpty else { return }
            viewModel.saveRecentSearch()
        }
        .sheet(isPresented: $viewModel.showingFilterSheet) {
            if let filterType = viewModel.selectedFilterType {
                FilterConfigurationView(filters: $viewModel.filters, filterType: filterType)
            }
        }
        // A container of its own, or the identifier is stamped over every scroll view inside
        // and `search_results` / `search_scope_bar` can never be found.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("feed_search_page")
    }

    private var header: some View {
        VStack(spacing: 0) {
            SearchScopeBar(selection: $viewModel.scope)
                .padding(.vertical, 4)

            if !viewModel.availableFilters.isEmpty {
                FilterChipsView(
                    filters: $viewModel.filters,
                    types: viewModel.availableFilters,
                    onFilterTap: { viewModel.selectFilter($0) }
                )
            }

            Divider()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isIdle {
            SearchIdleView(
                recents: viewModel.recentSearches,
                trending: viewModel.trending,
                routeBuilder: routeBuilder,
                onSelectRecent: { viewModel.selectRecentSearch($0) },
                onRemoveRecent: { viewModel.removeRecentSearch($0) },
                onClearRecents: { viewModel.clearRecentSearches() }
            )
            .task { await viewModel.loadTrendingIfNeeded() }
        } else {
            results
        }
    }

    private var results: some View {
        FeedStateView(
            phase: phase,
            // A scope switch keeps the previous rows and dims them rather than tearing the list
            // down for a spinner and building a new one — that teardown is what made switching
            // scopes after a search jump around.
            isRefreshing: viewModel.isReloading,
            allowsCancel: true,
            emptyConfiguration: NoResultViewConfiguration(
                primaryButtonAction: { viewModel.retry() },
                primaryButtonText: L10n.searchEmptyRetry,
                secondaryButtonAction: { viewModel.clear() },
                secondaryButtonText: L10n.searchEmptyClear,
                headline: L10n.searchEmptyTitle(viewModel.query.trimmingCharacters(in: .whitespaces)),
                subheadline: L10n.searchEmptyMessage
            ),
            retryAction: { viewModel.retry() },
            cancelAction: { viewModel.clear() },
            content: {
                SearchResultsList(
                    items: viewModel.items,
                    showsKind: viewModel.scope == .multi,
                    canLoadMore: viewModel.canLoadMore,
                    resultsGeneration: viewModel.resultsGeneration,
                    routeBuilder: routeBuilder,
                    onRowAppear: { viewModel.loadMoreIfNeeded(currentItem: $0) }
                )
            }
        )
    }

    private var phase: FeedLoadPhase {
        // A query typed but still inside the debounce has not searched yet; it is about to.
        if viewModel.isLoadingFirstPage || !viewModel.hasSearched {
            return .loading
        }
        // `isReloading` deliberately does not appear here: it renders as an overlay on the
        // results that are already up, not as a different phase.
        if let message = viewModel.errorMessage {
            return .error(message: message)
        }
        return viewModel.items.isEmpty ? .empty : .loaded
    }
}

/// The paginated result rows, with a spinner row while more pages are waiting.
@available(iOS 16, *)
struct SearchResultsList<Route: Hashable>: View {
    let items: [SearchResultItem]
    let showsKind: Bool
    let canLoadMore: Bool
    let resultsGeneration: Int
    let routeBuilder: (SearchResultItem) -> Route?
    let onRowAppear: (SearchResultItem) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(items) { item in
                    row(for: item)
                        .onAppear { onRowAppear(item) }
                }

                if canLoadMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .accessibilityIdentifier("search_results_loading_more")
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.immediately)
            // Rows from two different scopes share no identity, so letting SwiftUI animate the
            // diff is a full-list churn rather than a transition.
            .animation(nil, value: items)
            .onChange(of: resultsGeneration) {
                // Land at the top of the new results instead of wherever the previous scope
                // happened to be scrolled to.
                guard let first = items.first else { return }
                proxy.scrollTo(first.id, anchor: .top)
            }
            .accessibilityIdentifier("search_results")
        }
    }

    @ViewBuilder
    private func row(for item: SearchResultItem) -> some View {
        if let route = routeBuilder(item) {
            NavigationLink(value: route) {
                SearchResultRow(item: item, showsKind: showsKind)
            }
            .accessibilityIdentifier("search_result_\(item.id)")
        } else {
            SearchResultRow(item: item, showsKind: showsKind)
                .accessibilityIdentifier("search_result_\(item.id)")
        }
    }
}

public extension EnvironmentValues {
    /// Where `SearchPage` puts its field. `.automatic` suits every host that gives search a
    /// place of its own — a search-role tab, a navigation or bottom bar. A host that cannot —
    /// the iPhone "More" list, which drops a search tab's field — pins it under the title
    /// with `.navigationBarDrawer(displayMode: .always)`.
    @Entry var searchPageFieldPlacement: SearchFieldPlacement = .automatic
}

#if DEBUG
@available(iOS 16, *)
#Preview("Results list — more pages waiting") {
    NavigationStack {
        SearchResultsList(
            items: StubSearchService.items(for: .multi, query: "super", page: 1, count: 4),
            showsKind: true,
            canLoadMore: true,
            resultsGeneration: 0,
            routeBuilder: { _ in 1 },
            onRowAppear: { _ in }
        )
    }
}
#endif
