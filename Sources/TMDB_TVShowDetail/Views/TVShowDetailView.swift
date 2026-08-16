import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 15, *)
public struct TVShowDetailView: View {
    // MARK: - Store / StateObject

    public enum ViewState {
        case initial
        case loading
        case loaded(TVShowDetailModel)
        case error(String)

        var isInitial: Bool {
            if case .initial = self { return true }
            return false
        }

        var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }
    }

    @MainActor
    final class Store: ObservableObject {
        @Published var state: ViewState = .initial

        private let apiService: TMDBAPIService
        private let tvShowId: Int

        init(apiService: TMDBAPIService, tvShowId: Int) {
            self.apiService = apiService
            self.tvShowId = tvShowId
        }

        /// Entry point for `.task`: nothing happens unless the show has never been loaded.
        func load() async {
            guard state.isInitial else { return }
            await fetch()
        }

        /// Pull to refresh and the error view's retry. Refuses to stack on an in-flight request.
        func reload() async {
            guard !state.isLoading else { return }
            await fetch()
        }

        private func fetch() async {
            state = .loading
            do {
                let result: TVShowDetailModel = try await apiService.request(.tvShowDetail(show: tvShowId))
                state = .loaded(result)
            } catch {
                // Leaving the screen cancels the request; going back to `initial` lets the next
                // appearance load again instead of showing a cancellation as a failure.
                guard !Task.isCancelled else {
                    state = .initial
                    return
                }
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Dependencies / Properties

    @EnvironmentObject private var themeManager: ThemeManager
    private let apiService: TMDBAPIService
    let tvShowId: Int
    @StateObject private var store: Store
    @State private var isRefreshing = false

    // MARK: - Initialization

    public init(tvShowId: Int, apiService: TMDBAPIService) {
        self.tvShowId = tvShowId
        self.apiService = apiService
        _store = StateObject(wrappedValue: Store(apiService: apiService, tvShowId: tvShowId))
    }

    // MARK: - Body

    public var body: some View {
        contentView
            .refreshable {
                await refreshTVShowDetail()
            }
            .task(id: tvShowId) {
                await store.load()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ThemeSwitchButton()
                }
            }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch store.state {
        case .initial, .loading:
            LoadingStateView()
        case .loaded(let tvShow):
            TVShowDetailContentView(apiService: apiService, tvShow: tvShow)
        case .error(let message):
            ErrorStateView(
                message: message,
                retryAction: { await store.reload() }
            )
        }
    }

    // MARK: - Data Loading

    private func refreshTVShowDetail() async {
        defer { isRefreshing = false }
        isRefreshing = true
        await store.reload()
    }
}

#if DEBUG
@available(iOS 15, *)
#Preview {
    TVShowDetailView(tvShowId: 1399, apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))
        .environmentObject(ThemeManager.shared)
}
#endif
