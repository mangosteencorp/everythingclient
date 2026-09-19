import Combine
import Foundation
import TMDB_Shared_Backend

/// Drives the scoped search page: one debounced query, one scope, one paginated result list.
///
/// Deliberately separate from `MovieFeedViewModel`, whose search shares state with the feeds —
/// which is why its results could never paginate.
@MainActor
public final class SearchViewModel: ObservableObject {
    @Published public var query = ""
    @Published public var scope: SearchScope = .multi
    @Published public private(set) var items: [SearchResultItem] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    /// True once a query has been run, so the page can tell "nothing typed yet" from "no hits".
    @Published public private(set) var hasSearched = false

    private let service: TMDBSearchServicing
    private var page = 1
    private var totalPages = 1
    private var searchTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    public init(service: TMDBSearchServicing) {
        self.service = service

        // Same debounce the feed view models use: one request per pause, not per keystroke.
        $query
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in self?.runSearch() }
            .store(in: &cancellables)

        $scope
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.runSearch() }
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

    public func runSearch() {
        searchTask?.cancel()
        loadMoreTask?.cancel()
        page = 1
        totalPages = 1

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            items = []
            errorMessage = nil
            isLoading = false
            hasSearched = false
            return
        }

        isLoading = true
        errorMessage = nil
        let scope = scope
        searchTask = Task { [weak self] in
            guard let self else { return }
            let result = await service.search(scope: scope, query: trimmed, page: nil)
            guard !Task.isCancelled else { return }
            hasSearched = true
            isLoading = false
            switch result {
            case let .success(response):
                items = response.items
                page = response.page
                totalPages = response.totalPages
            case let .failure(error):
                items = []
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Endless scrolling: called as the last row appears.
    public func loadMoreIfNeeded(currentItem: SearchResultItem) {
        guard currentItem.id == items.last?.id,
              page < totalPages,
              loadMoreTask == nil,
              !isLoading else { return }

        let nextPage = page + 1
        let scope = scope
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        loadMoreTask = Task { [weak self] in
            guard let self else { return }
            let result = await service.search(scope: scope, query: trimmed, page: nextPage)
            defer { loadMoreTask = nil }
            guard !Task.isCancelled, case let .success(response) = result else { return }
            // A scope or query change while this was in flight already reset the list.
            guard self.scope == scope, self.page == nextPage - 1 else { return }
            items += response.items
            page = response.page
            totalPages = response.totalPages
        }
    }
}
