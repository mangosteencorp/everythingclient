import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 15, *)
public struct TVShowDetailView: View {
    // MARK: - Dependencies
    private let apiService: TMDBAPIService
    @EnvironmentObject private var themeManager: ThemeManager
    
    // MARK: - View State (No ViewModel needed!)
    enum ViewState {
        case loading
        case loaded(TVShowDetailModel)
        case error(String)
    }
    
    // MARK: - Properties
    let tvShowId: Int
    @State private var viewState: ViewState = .loading
    @State private var isRefreshing = false
    
    // MARK: - Initialization
    public init(tvShowId: Int, apiService: TMDBAPIService) {
        self.tvShowId = tvShowId
        self.apiService = apiService
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            contentView
                .refreshable {
                    await refreshTVShowDetail()
                }
                .task(id: tvShowId) {
                    await loadTVShowDetail()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ThemeSwitchButton()
                    }
                }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch viewState {
        case .loading:
            LoadingStateView()
        case .loaded(let tvShow):
            TVShowDetailContentView(tvShow: tvShow)
        case .error(let message):
            ErrorStateView(
                message: message,
                retryAction: { await loadTVShowDetail() }
            )
        }
    }
    
    // MARK: - Data Loading
    private func loadTVShowDetail() async {
        viewState = .loading
        do {
            let result: TVShowDetailModel = try await apiService.request(.tvShowDetail(show: tvShowId))
            viewState = .loaded(result)
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
    
    private func refreshTVShowDetail() async {
        defer { isRefreshing = false }
        isRefreshing = true
        await loadTVShowDetail()
    }
}

#if DEBUG
@available(iOS 15, *)
#Preview {
    TVShowDetailView(tvShowId: 1399, apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))
        .environmentObject(ThemeManager.shared)
}
#endif
