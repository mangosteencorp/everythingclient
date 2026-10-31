#if DEBUG
import SwiftUI
import third_party
import TMDB_Shared_Backend

/// Every movie detail preview as a view of its own, so Xcode's canvas, the integration launcher
/// and the screenshot run all render the same thing. Everything but `demo` is seeded with the
/// sample movie and never reaches TMDB; `demo` is the live page.
public enum TMDBMovieDetailPreviewCatalog: String, CaseIterable, Identifiable {
    public var id: String {
        rawValue
    }

    case demo
    case detailPage
    case creditSection
    case watchProviders
    case watchProvidersLoading
    case watchProvidersError
    case ostSection
    case jellyfinSection

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            TMDBMovieDetailDemoView()
        case .detailPage:
            NavigationStack { Self.loadedPage }
        case .creditSection:
            MovieCreditSection(movieId: exampleMovieCredits.id, creditsViewModel: Self.creditsViewModel, personRouteBuilder: { $0 })
        case .watchProviders, .watchProvidersLoading, .watchProvidersError:
            MovieWatchProvidersSection(movieId: exampleMovieDetail.id, watchProvidersViewModel: watchProvidersViewModel)
        case .ostSection:
            List {
                MovieOSTSection(ostViewModel: Self.ostViewModel)
            }
        case .jellyfinSection:
            List {
                Section {
                    MovieJellyfinSection(movieTitle: "Dune", movieId: 438_631, jellyfinViewModel: Self.jellyfinViewModel)
                }
            }
        }
    }

    @MainActor
    private var watchProvidersViewModel: MovieWatchProvidersViewModel {
        let viewModel = MovieWatchProvidersViewModel(apiService: PreviewTMDBAPIRequester())
        switch self {
        case .watchProvidersLoading: viewModel.state = .loading
        case .watchProvidersError: viewModel.state = .error("The Internet connection appears to be offline.")
        default: viewModel.state = .success(.example)
        }
        return viewModel
    }
}

private extension TMDBMovieDetailPreviewCatalog {
    /// The page with every section already loaded, so it never asks TMDB for anything.
    @MainActor
    static var loadedPage: some View {
        let apiService = PreviewTMDBAPIRequester()
        let movieDetailViewModel = MovieDetailViewModel(apiService: apiService)
        movieDetailViewModel.state = .success(exampleMovieDetail)
        let watchProvidersViewModel = MovieWatchProvidersViewModel(apiService: apiService)
        watchProvidersViewModel.state = .success(.example)

        return MovieDetailPage(
            movie: exampleMovieDetail,
            // Only used to build view models, and every one is passed in.
            apiService: TMDBAPIService(apiKey: ""),
            movieDetailViewModel: movieDetailViewModel,
            creditsViewModel: creditsViewModel,
            watchProvidersViewModel: watchProvidersViewModel,
            ostViewModel: MovieOSTViewModel(),
            jellyfinViewModel: MovieJellyfinViewModel(),
            discoverMovieByKeywordRouteBuilder: { _ in 1 },
            photoSlidesRouteBuilder: { _, index in index }
        )
    }

    @MainActor
    static var creditsViewModel: MovieCastingViewModel {
        let viewModel = MovieCastingViewModel(apiService: PreviewTMDBAPIRequester())
        viewModel.state = .success(exampleMovieCredits)
        return viewModel
    }

    @MainActor
    static var ostViewModel: MovieOSTViewModel {
        let viewModel = MovieOSTViewModel()
        viewModel.state = .success([
            MovieOSTAlbumDisplayModel(
                id: "1",
                title: "Superman (Original Motion Picture Soundtrack)",
                artistName: "Various Artists",
                trackCount: 24,
                artwork: nil,
                url: URL(string: "https://music.apple.com")
            ),
        ])
        return viewModel
    }

    @MainActor
    static var jellyfinViewModel: MovieJellyfinViewModel {
        let viewModel = MovieJellyfinViewModel()
        viewModel.state = .found(
            JellyfinMovieMatch(
                id: "abc",
                title: "Dune (2021)",
                runtimeSeconds: 9315,
                playedFraction: 0.35,
                resumeSeconds: 3260,
                isPlayed: false
            )
        )
        return viewModel
    }
}
#endif
