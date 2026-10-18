#if DEBUG
import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

/// Every TV show detail preview as a view of its own, so Xcode's canvas, the integration launcher
/// and the screenshot run all render the same thing. Everything but `demo` answers from
/// `PreviewTMDBAPIRequester`; `demo` is the live Game of Thrones page.
public enum TMDBTVShowDetailPreviewCatalog: String, CaseIterable {
    case demo
    case detailPage
    case detailContent
    case watchProviders
    case watchProvidersOffline
    case similarSection

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            TMDBTVShowDetailDemoView()
        case .similarSection:
            SimilarTVSection(viewModel: SimilarTVViewModel(apiService: Self.apiService, tvShowId: Self.show.id))
        default:
            themed.environmentObject(ThemeManager.shared)
        }
    }

    @MainActor @ViewBuilder
    private var themed: some View {
        switch self {
        case .detailPage:
            TVShowDetailView(tvShowId: Self.show.id, apiService: Self.apiService)
        case .detailContent:
            TVShowDetailContentView(apiService: Self.apiService, tvShow: Self.show)
        case .watchProviders:
            TVShowWatchProvidersSection(tvShowId: Self.show.id, apiService: Self.apiService)
        default:
            TVShowWatchProvidersSection(tvShowId: Self.show.id, apiService: PreviewTMDBAPIRequester())
        }
    }

    private static var show: TVShowDetailModel { .example }

    /// Game of Thrones, its providers and similar shows; anything else fails like a dropped connection.
    private static var apiService: PreviewTMDBAPIRequester {
        PreviewTMDBAPIRequester([
            .tvShowDetail(show: show.id): show,
            .tvShowWatchProviders(show: show.id): WatchProviderResponse.example,
            .similarTVShows(show: show.id): TVShowListResultModel.example,
        ])
    }
}
#endif
