import PhotoListViewer
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
public struct MovieDetailPage<Route: Hashable>: View {
    var movie: Movie
    // Owned by the page: an @ObservedObject created in `init` is thrown away on every parent
    // redraw, which would reset each view model to `.initial` without `.task` running again.
    @StateObject var movieDetailViewModel: MovieDetailViewModel
    @StateObject var creditsViewModel: MovieCastingViewModel
    @StateObject var watchProvidersViewModel: MovieWatchProvidersViewModel
    @StateObject var ostViewModel: MovieOSTViewModel
    @StateObject var jellyfinViewModel: MovieJellyfinViewModel
    let apiService: TMDBAPIService
    let discoverMovieByKeywordRouteBuilder: (Int) -> Route
    let personRouteBuilder: ((Int) -> Route)?
    let photoSlidesRouteBuilder: (([String], Int) -> Route)?
    let pokedexRouteBuilder: (() -> Route)?

    public init(movieRoute: Movie,
                apiService: TMDBAPIService,
                discoverMovieByKeywordRouteBuilder: @escaping (Int) -> Route,
                personRouteBuilder: ((Int) -> Route)? = nil,
                photoSlidesRouteBuilder: (([String], Int) -> Route)? = nil,
                pokedexRouteBuilder: (() -> Route)? = nil) {
        // Convert MovieRouteModel to Movie
        self.init(
            movie: movieRoute,
            apiService: apiService,
            movieDetailViewModel: MovieDetailViewModel(apiService: apiService),
            creditsViewModel: MovieCastingViewModel(apiService: apiService),
            watchProvidersViewModel: MovieWatchProvidersViewModel(apiService: apiService),
            ostViewModel: MovieOSTViewModel(),
            jellyfinViewModel: MovieJellyfinViewModel(),
            discoverMovieByKeywordRouteBuilder: discoverMovieByKeywordRouteBuilder,
            personRouteBuilder: personRouteBuilder,
            photoSlidesRouteBuilder: photoSlidesRouteBuilder,
            pokedexRouteBuilder: pokedexRouteBuilder
        )
    }

    public init(movieId: Int,
                apiService: TMDBAPIService,
                discoverMovieByKeywordRouteBuilder: @escaping (Int) -> Route,
                personRouteBuilder: ((Int) -> Route)? = nil,
                photoSlidesRouteBuilder: (([String], Int) -> Route)? = nil,
                pokedexRouteBuilder: (() -> Route)? = nil) {
        self.init(
            movieRoute: Movie.placeholder(id: movieId),
            apiService: apiService,
            discoverMovieByKeywordRouteBuilder: discoverMovieByKeywordRouteBuilder,
            personRouteBuilder: personRouteBuilder,
            photoSlidesRouteBuilder: photoSlidesRouteBuilder,
            pokedexRouteBuilder: pokedexRouteBuilder
        )
    }

    /// Designated initializer, also used by previews to inject view models in a chosen state.
    init(movie: Movie,
         apiService: TMDBAPIService,
         movieDetailViewModel: MovieDetailViewModel,
         creditsViewModel: MovieCastingViewModel,
         watchProvidersViewModel: MovieWatchProvidersViewModel,
         ostViewModel: MovieOSTViewModel,
         jellyfinViewModel: MovieJellyfinViewModel,
         discoverMovieByKeywordRouteBuilder: @escaping (Int) -> Route,
         personRouteBuilder: ((Int) -> Route)? = nil,
         photoSlidesRouteBuilder: (([String], Int) -> Route)? = nil,
         pokedexRouteBuilder: (() -> Route)? = nil) {
        self.movie = movie
        self.apiService = apiService
        _movieDetailViewModel = StateObject(wrappedValue: movieDetailViewModel)
        _creditsViewModel = StateObject(wrappedValue: creditsViewModel)
        _watchProvidersViewModel = StateObject(wrappedValue: watchProvidersViewModel)
        _ostViewModel = StateObject(wrappedValue: ostViewModel)
        _jellyfinViewModel = StateObject(wrappedValue: jellyfinViewModel)
        self.discoverMovieByKeywordRouteBuilder = discoverMovieByKeywordRouteBuilder
        self.personRouteBuilder = personRouteBuilder
        self.photoSlidesRouteBuilder = photoSlidesRouteBuilder
        self.pokedexRouteBuilder = pokedexRouteBuilder
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            List {
                Section {
                    MovieCoverRow(movie: displayedMovie)
                        .frame(height: 250)
                }
                if let errorMessage = movieDetailViewModel.state.errorMessage {
                    Section {
                        SectionRetryView(message: errorMessage) {
                            await movieDetailViewModel.reload(movieId: movie.id)
                        }
                    }
                }
                Section {
                    MovieOverview(movie: displayedMovie)
                }
                Section {
                    MovieOSTSection(ostViewModel: ostViewModel)
                }
                if let photoSlidesRouteBuilder, !displayedMovie.photoPaths.isEmpty {
                    Section {
                        PhotoCarouselView(
                            title: L10n.photosSectionTitle,
                            imagePaths: displayedMovie.photoPaths,
                            photoSlidesRouteBuilder: photoSlidesRouteBuilder
                        )
                    }
                }
                Section {
                    if let kwList = displayedMovie.keywords?.keywords, !kwList.isEmpty {
                        MovieKeywords(
                            keywords: kwList,
                            discoverMovieByKeywordRouteBuilder: discoverMovieByKeywordRouteBuilder
                        )
                    }
                    if let locations = extractLocations(from: displayedMovie.overview), !locations.isEmpty {
                        MovieLocations(locations: locations)
                    }
                    if let pokedexRouteBuilder, PokemonMovieMatcher.shouldShowPokedexButton(for: displayedMovie) {
                        NavigationLink(value: pokedexRouteBuilder()) {
                            Label("Open Pokédex", systemImage: "sparkles")
                        }
                    }
                    MovieCreditSection(
                        movieId: movie.id,
                        creditsViewModel: creditsViewModel,
                        personRouteBuilder: personRouteBuilder
                    )
                }
                Section {
                    MovieWatchProvidersSection(movieId: movie.id, watchProvidersViewModel: watchProvidersViewModel)
                }
                if jellyfinViewModel.isVisible {
                    Section {
                        MovieJellyfinSection(
                            movieTitle: displayedMovie.userTitle,
                            movieId: movie.id,
                            jellyfinViewModel: jellyfinViewModel
                        )
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle(Text(displayedMovie.userTitle), displayMode: .large)
        }
        // Separate tasks so the two requests run concurrently instead of being serialised.
        // SwiftUI cancels them when the page goes away, and each view model only loads once.
        .task {
            await movieDetailViewModel.load(movieId: movie.id)
        }
        .task {
            await watchProvidersViewModel.load(movieId: movie.id)
        }
        // The title starts as the placeholder and changes once the detail resolves, which is what
        // the previous `onChange` was for.
        .task(id: displayedMovie.userTitle) {
            await ostViewModel.load(for: displayedMovie.userTitle)
        }
        // Same story as the OST search: the Jellyfin library is searched by title, so the lookup
        // waits for the placeholder title to resolve into the real one.
        .task(id: displayedMovie.userTitle) {
            await jellyfinViewModel.load(title: displayedMovie.userTitle, tmdbID: movie.id)
        }
    }

    var displayedMovie: Movie {
        movieDetailViewModel.state.value ?? movie
    }

    private func extractLocations(from overview: String) -> [String]? {
        let locations = overview.detectGeographicalEntities(in: overview)
        return locations.isEmpty ? nil : locations
    }
}

#if DEBUG

@available(iOS 16.0, *)
@MainActor
let exampleMovieDetailPage: MovieDetailPage = {
    let apiService = TMDBAPIService(apiKey: debugTMDBAPIKey)
    let movieDetailVM = MovieDetailViewModel(apiService: apiService)
    let creditVM = MovieCastingViewModel(apiService: apiService)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        movieDetailVM.state = .success(exampleMovieDetail)
        creditVM.state = .success(exampleMovieCredits)
    }

    return MovieDetailPage(
        movie: exampleMovieDetail,
        apiService: apiService,
        movieDetailViewModel: movieDetailVM,
        creditsViewModel: creditVM,
        watchProvidersViewModel: MovieWatchProvidersViewModel(apiService: apiService),
        ostViewModel: MovieOSTViewModel(),
        jellyfinViewModel: MovieJellyfinViewModel(),
        discoverMovieByKeywordRouteBuilder: { _ in 1 },
        photoSlidesRouteBuilder: { _, index in index }
    )
}()

@available(iOS 16.0, *)
#Preview {
    return NavigationView {
        exampleMovieDetailPage
    }
}
#endif
