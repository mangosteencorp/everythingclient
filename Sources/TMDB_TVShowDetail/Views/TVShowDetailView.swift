import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 15, *)
public struct TVShowDetailView: View {
    // MARK: - Store / StateObject

    public enum ViewState {
        case loading
        case loaded(TVShowDetailModel)
        case error(String)
    }

    final class Store: ObservableObject {
        @Published var state: ViewState = .loading

        private let apiService: TMDBAPIService
        private let tvShowId: Int

        init(apiService: TMDBAPIService, tvShowId: Int) {
            self.apiService = apiService
            self.tvShowId = tvShowId
        }

        @MainActor
        func fetch() async {
            // Log to help detect unexpected re-entrancy
            print("[TVShowDetail] fetch called for id=\(tvShowId) at \(Date())")
            state = .loading
            do {
                let result: TVShowDetailModel = try await apiService.request(.tvShowDetail(show: tvShowId))
                state = .loaded(result)
            } catch {
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
                await store.fetch()
            }
//            .onChange(of: store.state) { newValue in
//                print("[TVShowDetail] state changed: \(newValue)")
//            }
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
        case .loading:
            LoadingStateView()
        case .loaded(let tvShow):
            TVShowDetailContentView(tvShow: tvShow)
        case .error(let message):
            ErrorStateView(
                message: message,
                retryAction: { await store.fetch() }
            )
        }
    }

    // MARK: - Data Loading

    private func refreshTVShowDetail() async {
        defer { isRefreshing = false }
        isRefreshing = true
        await store.fetch()
    }
}

#if DEBUG
@available(iOS 15, *)
#Preview {
    TVShowDetailView(tvShowId: 1399, apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))
        .environmentObject(ThemeManager.shared)
}
#endif
