import Foundation
import TMDB_Shared_Backend

#if DEBUG
/// Serves every feed from sample data, so feed previews render offline and the same on every run.
struct PreviewFeedAPIService: APIServiceProtocol {
    /// When set, every request fails with it — the error state.
    var failure: Error?

    func fetchNowPlayingMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error> { movies(page: page) }
    func fetchPopularMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error> { movies(page: page) }
    func fetchTopRatedMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error> { movies(page: page) }
    func fetchUpcomingMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error> { movies(page: page) }
    func searchMovies(query: String, page: Int?) async -> Result<MovieListResponse, Error> { movies(page: page) }
    func fetchAiringTodayTVShows(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<TVShowListResponse, Error> { shows(page: page) }
    func fetchOnTheAirTVShows(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<TVShowListResponse, Error> { shows(page: page) }
    func searchTVShows(query: String, page: Int?) async -> Result<TVShowListResponse, Error> { shows(page: page) }

    // A single page: the feeds ask for the next one without checking `totalPages`, and repeating
    // the first would list every title twice.
    private func movies(page: Int?) -> Result<MovieListResponse, Error> {
        if let failure { return .failure(failure) }
        let results = (page ?? 1) == 1 ? Movie.previewMovies : []
        return .success(MovieListResponse(dates: nil, page: page ?? 1, results: results, totalPages: 1, totalResults: Movie.previewMovies.count))
    }

    private func shows(page: Int?) -> Result<TVShowListResponse, Error> {
        if let failure { return .failure(failure) }
        let results = (page ?? 1) == 1 ? TVShow.examples : []
        return .success(TVShowListResponse(page: page ?? 1, results: results, totalPages: 1, totalResults: TVShow.examples.count))
    }
}

// swiftlint:disable all
extension Movie {
    /// Artwork-free on purpose: a preview never waits on the image CDN.
    static var previewMovies: [Movie] { [
        Movie(id: 693_134, originalTitle: "Dune: Part Two", title: "Dune: Part Two", overview: "Paul Atreides unites with Chani and the Fremen while on a path of revenge against the conspirators who destroyed his family.", posterPath: nil, backdropPath: nil, popularity: 320.5, voteAverage: 8.2, voteCount: 5200, releaseDate: "2024-02-27", genres: nil, video: false),
        Movie(id: 1_022_789, originalTitle: "Inside Out 2", title: "Inside Out 2", overview: "Teenager Riley's mind headquarters is undergoing a sudden demolition to make room for something entirely unexpected: new Emotions!", posterPath: nil, backdropPath: nil, popularity: 280.1, voteAverage: 7.6, voteCount: 4100, releaseDate: "2024-06-11", genres: nil, video: false),
        Movie(id: 533_535, originalTitle: "Deadpool & Wolverine", title: "Deadpool & Wolverine", overview: "A listless Wade Wilson toils away in civilian life with his days as the morally flexible mercenary behind him.", posterPath: nil, backdropPath: nil, popularity: 250.9, voteAverage: 7.7, voteCount: 6000, releaseDate: "2024-07-24", genres: nil, video: false),
        Movie(id: 1_184_918, originalTitle: "The Wild Robot", title: "The Wild Robot", overview: "After a shipwreck, an intelligent robot called Roz is stranded on an uninhabited island.", posterPath: nil, backdropPath: nil, popularity: 190.4, voteAverage: 8.5, voteCount: 3000, releaseDate: "2024-09-12", genres: nil, video: false),
    ] }
}
// swiftlint:enable all
#endif
