import SwiftUI
import TMDB_Shared_UI
import TMDB_Shared_Backend
public struct MovieDetailPage: View {
    var movie: Movie
    @ObservedObject var movieDetailViewModel: MovieDetailViewModel
    @ObservedObject var creditsViewModel: MovieCastingViewModel
    let apiService: TMDBAPIService
    public init(movieRoute: MovieRouteModel, apiKey: String) {
        // Convert MovieRouteModel to Movie
        self.movie = Movie(id: movieRoute.id, original_title: movieRoute.originalTitle ?? "", title: movieRoute.title, overview: movieRoute.overview, poster_path: movieRoute.posterPath, backdrop_path: movieRoute.backdropPath, popularity: movieRoute.popularity ?? 0.0, vote_average: movieRoute.voteAverage, vote_count: movieRoute.voteCount, release_date: movieRoute.releaseDate, genres: nil, runtime: nil, status: nil, video: false)
        self.apiService = TMDBAPIService(apiKey: apiKey)
        self.movieDetailViewModel = MovieDetailViewModel(apiService: self.apiService)
        self.creditsViewModel = MovieCastingViewModel(apiService: self.apiService)
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
                    if let kwList = getMovie().keywords?.keywords, kwList.count > 0 {
                        MovieKeywords(keywords: kwList)
                    }
                    MovieCreditSection(movieId: movie.id, creditsViewModel: creditsViewModel)
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle(Text(movie.userTitle), displayMode: .large)
        }.onFirstAppear {
            movieDetailViewModel.fetchMovieDetail(movieId: movie.id)
        }
    }
    func getMovie() -> Movie {
        if case .success(let mv) = movieDetailViewModel.state {
            return mv
        }
        return movie
    }
}
#if DEBUG
let exampleMovieDetailPage: MovieDetailPage = {
    var p = MovieDetailPage(
        movieRoute: MovieRouteModel(
            id: exampleMovieDetail.id,
            title: exampleMovieDetail.title,
            overview: exampleMovieDetail.original_title,
            posterPath: exampleMovieDetail.overview,
            backdropPath: exampleMovieDetail.backdrop_path,
            voteAverage: exampleMovieDetail.vote_average,
            voteCount: exampleMovieDetail.vote_count,
            releaseDate: exampleMovieDetail.release_date,
            popularity: exampleMovieDetail.popularity,
            originalTitle: exampleMovieDetail.original_title
        ),
        apiKey: "dummy-key"
    )
    let apiService = TMDBAPIService(apiKey: "dummy-key")
    let movieDetailVM = MovieDetailViewModel(apiService: apiService)
    
    let creditVM = MovieCastingViewModel(apiService: apiService)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        movieDetailVM.state = .success(exampleMovieDetail)
        creditVM.state = .success(exampleMovieCredits)
    }
    p.creditsViewModel = creditVM
    p.movieDetailViewModel = movieDetailVM
    return p
}()

#Preview {
    return NavigationView {
        exampleMovieDetailPage
    }
}
#endif
