#if DEBUG
import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend

/// Every Discover preview as a view of its own, so Xcode's canvas, the integration launcher and
/// the screenshot run all render the same thing. `demo` and `homeLive` load from TMDB; the rest
/// answer from `PreviewUseCase` sample data.
public enum TMDBDiscoverPreviewCatalog: String, CaseIterable {
    case demo
    case homeLive
    case home
    case homeRepresentable
    case bannerCell
    case listPage
    case listController
    case listContent
    case listPageContent

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            TMDBDiscoverDemoView()
        case .homeLive:
            UIViewControllerPreview { HomeDiscoverViewController(viewModel: Self.liveHomeViewModel) }
        case .home:
            UIViewControllerPreview { HomeDiscoverViewController(viewModel: .preview()) }
        case .homeRepresentable:
            HomeDiscoverViewControllerRepresentable(
                viewModel: .preview(),
                onGenreTapped: { _ in },
                onTVGenreTapped: { _ in },
                onCastTapped: { _ in },
                onTrendingItemTapped: { _ in }
            )
        case .bannerCell:
            // The default layout has no banner section, so the banner cell is previewed on its own.
            UIViewPreview { BannerCell(frame: CGRect(x: 0, y: 0, width: 360, height: 80)) }
                .frame(width: 360, height: 80)
        case .listPage:
            NavigationStack {
                TVShowListViewControllerRepresentable(viewModel: .preview())
            }
        case .listController:
            UIViewControllerPreview { UINavigationController(rootViewController: TVShowListViewController(viewModel: .preview())) }
        case .listContent:
            TVShowListContent(movies: Movie.exampleMovies, mediaType: .movie, detailRouteBuilder: { _, _ in 0 })
        case .listPageContent:
            NavigationStack {
                TVShowListPageContent(
                    viewModel: .preview(),
                    type: .discoverWithGenre(Genre(id: 28, name: "Action")),
                    detailRouteBuilder: { id, _ in id }
                )
            }
        }
    }

    /// Home backed by the real TMDB repository.
    @MainActor
    private static var liveHomeViewModel: HomeDiscoverViewModel {
        let repository = MovieRepositoryImpl(apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))
        return HomeDiscoverViewModel(
            fetchGenresUseCase: DefaultFetchGenresUseCase(repository: repository),
            fetchTVGenresUseCase: DefaultFetchTVGenresUseCase(repository: repository),
            fetchPopularPeopleUseCase: DefaultFetchPopularPeopleUseCase(repository: repository),
            fetchTrendingItemsUseCase: DefaultFetchTrendingItemsUseCase(repository: repository)
        )
    }
}
#endif
