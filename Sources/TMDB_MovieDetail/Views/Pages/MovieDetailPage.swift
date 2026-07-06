import PhotoListViewer
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
public struct MovieDetailPage<Route: Hashable>: View {
    var movie: Movie
    @ObservedObject var movieDetailViewModel: MovieDetailViewModel
    @ObservedObject var creditsViewModel: MovieCastingViewModel
    @ObservedObject var watchProvidersViewModel: MovieWatchProvidersViewModel
    @ObservedObject var ostViewModel: MovieOSTViewModel
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
        movie = movieRoute
        self.apiService = apiService
        movieDetailViewModel = MovieDetailViewModel(apiService: self.apiService)
        creditsViewModel = MovieCastingViewModel(apiService: self.apiService)
        watchProvidersViewModel = MovieWatchProvidersViewModel(apiService: self.apiService)
        ostViewModel = MovieOSTViewModel()
        self.discoverMovieByKeywordRouteBuilder = discoverMovieByKeywordRouteBuilder
        self.personRouteBuilder = personRouteBuilder
        self.photoSlidesRouteBuilder = photoSlidesRouteBuilder
        self.pokedexRouteBuilder = pokedexRouteBuilder
    }

    public init(movieId: Int,
                apiService: TMDBAPIService,
                discoverMovieByKeywordRouteBuilder: @escaping (Int) -> Route,
                personRouteBuilder: ((Int) -> Route)? = nil,
                photoSlidesRouteBuilder: (([String], Int) -> Route)? = nil,
                pokedexRouteBuilder: (() -> Route)? = nil) {
        movie = Movie.placeholder(id: movieId)
        self.apiService = apiService
        movieDetailViewModel = MovieDetailViewModel(apiService: self.apiService)
        creditsViewModel = MovieCastingViewModel(apiService: self.apiService)
        watchProvidersViewModel = MovieWatchProvidersViewModel(apiService: self.apiService)
        ostViewModel = MovieOSTViewModel()
        self.discoverMovieByKeywordRouteBuilder = discoverMovieByKeywordRouteBuilder
        self.personRouteBuilder = personRouteBuilder
        self.photoSlidesRouteBuilder = photoSlidesRouteBuilder
        self.pokedexRouteBuilder = pokedexRouteBuilder
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            List {
                Section {
                    MovieCoverRow(movie: getMovie())
                        .frame(height: 250)
                }
                Section {
                    MovieOverview(movie: getMovie())
                }
                Section {
                    MovieOSTSection(ostViewModel: ostViewModel)
                }
                if let photoSlidesRouteBuilder, !getMovie().photoPaths.isEmpty {
                    Section {
                        PhotoCarouselView(
                            title: L10n.photosSectionTitle,
                            imagePaths: getMovie().photoPaths,
                            photoSlidesRouteBuilder: photoSlidesRouteBuilder
                        )
                    }
                }
                Section {
                    if let kwList = getMovie().keywords?.keywords, !kwList.isEmpty {
                        MovieKeywords(
                            keywords: kwList,
                            discoverMovieByKeywordRouteBuilder: discoverMovieByKeywordRouteBuilder
                        )
                    }
                    if let locations = extractLocations(from: getMovie().overview), !locations.isEmpty {
                        MovieLocations(locations: locations)
                    }
                    if let pokedexRouteBuilder, PokemonMovieMatcher.shouldShowPokedexButton(for: getMovie()) {
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
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle(Text(getMovie().userTitle), displayMode: .large)
        }.onFirstAppear {
            movieDetailViewModel.fetchMovieDetail(movieId: movie.id)
            watchProvidersViewModel.fetchWatchProviders(movieId: movie.id)
            ostViewModel.load(for: getMovie().userTitle)
        }
        .onChange(of: getMovie().userTitle) { newTitle in
            ostViewModel.load(for: newTitle)
        }
    }

    func getMovie() -> Movie {
        if case let .success(mov) = movieDetailViewModel.state {
            return mov
        }
        return movie
    }

    private func extractLocations(from overview: String) -> [String]? {
        let locations = overview.detectGeographicalEntities(in: overview)
        return locations.isEmpty ? nil : locations
    }
}

#if DEBUG

@available(iOS 16.0, *)
let exampleMovieDetailPage: MovieDetailPage = {
    let apiService = TMDBAPIService(apiKey: debugTMDBAPIKey)
    var page = MovieDetailPage(
        movieRoute: exampleMovieDetail,
        apiService: apiService,
        discoverMovieByKeywordRouteBuilder: {_ in 1},
        photoSlidesRouteBuilder: { _, index in index }
    )

    let movieDetailVM = MovieDetailViewModel(apiService: apiService)

    let creditVM = MovieCastingViewModel(apiService: apiService)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        movieDetailVM.state = .success(exampleMovieDetail)
        creditVM.state = .success(exampleMovieCredits)
    }
    page.creditsViewModel = creditVM
    page.movieDetailViewModel = movieDetailVM
    return page
}()

@available(iOS 16.0, *)
#Preview {
    return NavigationView {
        exampleMovieDetailPage
    }
}
#endif
