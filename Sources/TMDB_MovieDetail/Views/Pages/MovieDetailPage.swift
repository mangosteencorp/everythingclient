import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
public struct MovieDetailPage<Route: Hashable>: View {
    var movie: Movie
    @ObservedObject var movieDetailViewModel: MovieDetailViewModel
    @ObservedObject var creditsViewModel: MovieCastingViewModel
    @ObservedObject var watchProvidersViewModel: MovieWatchProvidersViewModel
    let apiService: TMDBAPIService
    let discoverMovieByKeywordRouteBuilder: (Int) -> Route

    public init(movieRoute: Movie,
                apiService: TMDBAPIService,
                discoverMovieByKeywordRouteBuilder: @escaping (Int) -> Route) {
        // Convert MovieRouteModel to Movie
        movie = movieRoute
        self.apiService = apiService
        movieDetailViewModel = MovieDetailViewModel(apiService: self.apiService)
        creditsViewModel = MovieCastingViewModel(apiService: self.apiService)
        watchProvidersViewModel = MovieWatchProvidersViewModel(apiService: self.apiService)
        self.discoverMovieByKeywordRouteBuilder = discoverMovieByKeywordRouteBuilder
    }

    public init(movieId: Int,
                apiService: TMDBAPIService,
                discoverMovieByKeywordRouteBuilder: @escaping (Int) -> Route) {
        movie = Movie.placeholder(id: movieId)
        self.apiService = apiService
        movieDetailViewModel = MovieDetailViewModel(apiService: self.apiService)
        creditsViewModel = MovieCastingViewModel(apiService: self.apiService)
        watchProvidersViewModel = MovieWatchProvidersViewModel(apiService: self.apiService)
        self.discoverMovieByKeywordRouteBuilder = discoverMovieByKeywordRouteBuilder
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
                    if let kwList = getMovie().keywords?.keywords, !kwList.isEmpty {
                        MovieKeywords(
                            keywords: kwList,
                            discoverMovieByKeywordRouteBuilder: discoverMovieByKeywordRouteBuilder
                        )
                    }
                    if let locations = extractLocations(from: getMovie().overview), !locations.isEmpty {
                        MovieLocations(locations: locations)
                    }
                    MovieCreditSection(movieId: movie.id, creditsViewModel: creditsViewModel)
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
        discoverMovieByKeywordRouteBuilder: {_ in 1}
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
