import Foundation
import TheMovieDBAPI
class MovieViewModel: ObservableObject {
    @Published var movies = [SingleMovieViewModel]()
    
    func loadNowPlaying() async {
        let result = await TheMovieDBAPIService.shared.loadNowPlayingMovies()
        if case .success(let movieResponse) = result {
            movies = movieResponse.results.map{
                SingleMovieViewModel(title: $0.title, 
                                     rating: Int($0.voteAverage),
                                     releaseDate: $0.releaseDate,
                                     description: $0.overview,
                                     poster: TheMovieDBAPIService.shared.buildImageUrl(imagePath: $0.posterPath))
            }
        }
    }
}

