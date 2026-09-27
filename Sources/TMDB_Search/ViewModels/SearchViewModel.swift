import Combine
import Foundation
import SwiftUI
import TMDB_Shared_Backend

/// Drives the scoped search page: one debounced query, one scope, one paginated result list.
///
/// Deliberately separate from `MovieFeedViewModel`, whose search shares state with the feeds —
/// which is why its results could never paginate.
@MainActor
public final class SearchViewModel: ObservableObject {
    @Published public var query = ""
    @Published public var scope: SearchScope = .multi
    @Published public var filters = SearchFilters()
    @Published public private(set) var items: [SearchResultItem] = []
    @Published public private(set) var errorMessage: String?
    /// True once a query has been run, so the page can tell "nothing typed yet" from "no hits".
    @Published public private(set) var hasSearched = false

    /// A search with nothing on screen yet — the only case that earns a full-page spinner.
    @Published public private(set) var isLoadingFirstPage = false
    /// A search running *over* results that are already visible: a scope switch, a filter change
    /// or a retry. Those keep the old rows and get an unobtrusive overlay, because swapping the
    /// whole page out and back in is what made the picker feel like it jumped.
    @Published public private(set) var isReloading = false

    /// Bumped whenever a fresh result set replaces the list, so the page can scroll back to the
    /// top instead of stranding you halfway down an unrelated list.
    @Published public private(set) var resultsGeneration = 0

    // The filter sheet lives here rather than in `@State` so that a scope change can close it —
    // a sheet configuring a chip the new scope does not support would have nothing to write to.
    @Published public var showingFilterSheet = false
    @Published public private(set) var selectedFilterType: FilterType?

    /// Queries the user committed to, newest first — what the page offers before anything is typed.
    @Published public private(set) var recentSearches: [String]
    /// Today's trending titles, shown under the recents on the idle page.
    @Published public private(set) var trending: [SearchResultItem] = []

    /// Enough to scan at a glance without the list turning into a history log.
    static let maxRecentSearches = 8

    private let service: TMDBSearchServicing
    private let recentsStore: RecentSearchesStoring
    private var page = 1
    private var totalPages = 1
    private var searchTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    /// The chips this scope can act on; empty for keywords and companies, whose endpoints take
    /// nothing but a query.
    public var availableFilters: [FilterType] { scope.supportedFilters }

    /// Only counts filters the current scope would actually send.
    public var hasActiveFilters: Bool { filters.narrowed(to: scope).hasActiveFilters }

    /// Nothing typed: the page shows recents and trending instead of results.
    public var isIdle: Bool { trimmedQuery.isEmpty }

    /// More pages are waiting behind the last row.
    public var canLoadMore: Bool { page < totalPages }

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    public init(
        service: TMDBSearchServicing,
        recentsStore: RecentSearchesStoring = UserDefaultsRecentSearchesStore()
    ) {
        self.service = service
        self.recentsStore = recentsStore
        recentSearches = recentsStore.load()

        // Same debounce the feed view models use: one request per pause, not per keystroke.
        $query
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in self?.runSearch() }
            .store(in: &cancellables)

        $scope
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] scope in
                guard let self else { return }
                // A sheet open on a chip the new scope does not support has nowhere to go.
                if let selected = selectedFilterType, !scope.supportedFilters.contains(selected) {
                    showingFilterSheet = false
                    selectedFilterType = nil
                }
                // `@Published` publishes from `willSet`, so `self.scope` here is still the scope
                // the user just left. The request has to be built from the emitted value; reading
                // it back off the view model is what made the results lag the picker by one step.
                runSearch(scope: scope, filters: filters)
            }
            .store(in: &cancellables)

        // Only re-request when the change touches a filter this scope sends: toggling a movie
        // year while searching keywords must not fire a redundant request.
        $filters
            .removeDuplicates { [weak self] old, new in
                let scope = self?.scope ?? .multi
                return old.narrowed(to: scope) == new.narrowed(to: scope)
            }
            .dropFirst()
            .sink { [weak self] filters in
                guard let self else { return }
                // Same `willSet` trap as the scope sink: `self.filters` is still the old set.
                runSearch(scope: scope, filters: filters)
            }
            .store(in: &cancellables)
    }

    deinit {
        searchTask?.cancel()
        loadMoreTask?.cancel()
    }

    public func retry() {
        runSearch()
    }

    public func clear() {
        query = ""
    }

    public func selectFilter(_ filterType: FilterType) {
        selectedFilterType = filterType
        showingFilterSheet = true
    }

    public func runSearch() {
        runSearch(scope: scope, filters: filters)
    }

    // MARK: - Recent searches

    /// Remembers the current query. Called when the user commits to it — submitting it or
    /// opening one of its results — rather than per debounced keystroke, which would fill the
    /// list with "d", "du", "dun".
    public func saveRecentSearch() {
        let trimmed = trimmedQuery
        guard !trimmed.isEmpty else { return }
        // Case-insensitive, so "dune" after "Dune" moves the entry up instead of duplicating it.
        let others = recentSearches.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        updateRecentSearches(Array(([trimmed] + others).prefix(Self.maxRecentSearches)))
    }

    /// Runs a recent search again; the debounced query sink does the searching.
    public func selectRecentSearch(_ recent: String) {
        query = recent
        saveRecentSearch()
    }

    public func removeRecentSearch(_ recent: String) {
        updateRecentSearches(recentSearches.filter { $0 != recent })
    }

    public func clearRecentSearches() {
        updateRecentSearches([])
    }

    private func updateRecentSearches(_ searches: [String]) {
        recentSearches = searches
        recentsStore.save(searches)
    }

    // MARK: - Trending

    /// Loads once per page; a failure just leaves the idle page with the recents alone.
    public func loadTrendingIfNeeded() async {
        guard trending.isEmpty, case let .success(items) = await service.trending() else { return }
        trending = items
    }

    private func runSearch(scope: SearchScope, filters: SearchFilters) {
        searchTask?.cancel()
        loadMoreTask?.cancel()
        loadMoreTask = nil
        page = 1
        totalPages = 1

        let trimmed = trimmedQuery
        guard !trimmed.isEmpty else {
            apply {
                items = []
                errorMessage = nil
                isLoadingFirstPage = false
                isReloading = false
                hasSearched = false
            }
            return
        }

        // Rows already on screen stay put while the next set loads; only an empty page gets the
        // full-height spinner.
        if items.isEmpty {
            isLoadingFirstPage = true
            isReloading = false
        } else {
            isLoadingFirstPage = false
            isReloading = true
        }
        errorMessage = nil

        searchTask = Task { [weak self] in
            guard let self else { return }
            let result = await service.search(scope: scope, query: trimmed, filters: filters, page: nil)
            guard !Task.isCancelled else { return }
            // Results are swapped without an implicit animation: cross-fading one scope's rows
            // into another's is the jitter, not a transition worth watching.
            apply {
                hasSearched = true
                isLoadingFirstPage = false
                isReloading = false
                switch result {
                case let .success(response):
                    items = response.items
                    page = response.page
                    totalPages = response.totalPages
                case let .failure(error):
                    items = []
                    errorMessage = error.localizedDescription
                }
                resultsGeneration += 1
            }
        }
    }

    /// Endless scrolling: called as the last row appears.
    public func loadMoreIfNeeded(currentItem: SearchResultItem) {
        guard currentItem.id == items.last?.id,
              page < totalPages,
              loadMoreTask == nil,
              !isLoadingFirstPage,
              // A scope or filter change is mid-flight and about to replace this list; paging
              // the outgoing scope would append rows that are discarded a moment later.
              !isReloading else { return }

        let nextPage = page + 1
        let scope = scope
        let filters = filters
        let trimmed = trimmedQuery
        loadMoreTask = Task { [weak self] in
            guard let self else { return }
            let result = await service.search(scope: scope, query: trimmed, filters: filters, page: nextPage)
            defer { loadMoreTask = nil }
            guard !Task.isCancelled, case let .success(response) = result else { return }
            // A scope or query change while this was in flight already reset the list.
            guard self.scope == scope, self.page == nextPage - 1 else { return }
            items += response.items
            page = response.page
            totalPages = response.totalPages
        }
    }

    /// Publishes a batch of changes with implicit animations off.
    ///
    /// Every mutation here lands in the same render pass, so the list does not animate rows out
    /// and back in while the spinner state flips underneath it.
    private func apply(_ mutations: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, mutations)
    }
}
