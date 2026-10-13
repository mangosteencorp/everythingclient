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
    case loadingState
    case errorState
    case header
    case posterImage
    case info
    case overview
    case genres
    case detailsSection
    case detailRow
    case creatorsSection
    case creators
    case seasons
    case seasonCard
    case watchProviders
    case watchProvidersOffline
    case similarSection
    case similarPosterCell

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            TMDBTVShowDetailDemoView()
        case .similarSection:
            SimilarTVSection(viewModel: SimilarTVViewModel(apiService: Self.apiService, tvShowId: Self.show.id))
        case .similarPosterCell:
            SimilarPosterCellView(entity: .placeholder(id: 1))
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
        case .loadingState:
            LoadingStateView()
        case .errorState:
            ErrorStateView(message: "The Internet connection appears to be offline.", retryAction: {})
        case .posterImage:
            PosterImageView(posterPath: Self.show.posterPath)
        case .info:
            ScrollView {
                TVShowInfoView(tvShow: Self.show)
                    .padding()
            }
        case .detailRow:
            DetailRow(title: "Status: Ended")
        case .creators:
            HStack {
                ForEach(Self.show.createdBy, id: \.id) { CreatorView(creator: $0) }
            }
        case .seasonCard:
            SeasonCardView(season: Self.show.seasons[0])
        case .watchProviders:
            TVShowWatchProvidersSection(tvShowId: Self.show.id, apiService: Self.apiService)
        case .watchProvidersOffline:
            TVShowWatchProvidersSection(tvShowId: Self.show.id, apiService: PreviewTMDBAPIRequester())
        default:
            section.padding()
        }
    }

    @MainActor @ViewBuilder
    private var section: some View {
        switch self {
        case .header:
            TVShowHeaderView(tvShow: Self.show)
        case .overview:
            TVShowOverviewSection(overview: "Seven noble families fight for control of the mythical land of Westeros.")
        case .genres:
            TVShowGenresSection(genres: Self.show.genres)
        case .detailsSection:
            TVShowDetailsSection(tvShow: Self.show)
        case .creatorsSection:
            TVShowCreatorsSection(creators: Self.show.createdBy)
        default:
            TVShowSeasonsView(tvShow: Self.show)
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
