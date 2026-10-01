import Foundation

#if DEBUG
/// Answers at once with a fixed value — one stand-in for every Discover use case in previews.
struct PreviewUseCase<Value> {
    let value: Value

    func execute() async -> Result<Value, Error> {
        .success(value)
    }
}

extension PreviewUseCase: FetchMoviesUseCase where Value == [Movie] {}
extension PreviewUseCase: FetchFavoriteTVShowsUseCase where Value == [Int] {}
extension PreviewUseCase: FetchGenresUseCase, FetchTVGenresUseCase where Value == [Genre] {}
extension PreviewUseCase: FetchPopularPeopleUseCase where Value == [PopularPerson] {}
extension PreviewUseCase: FetchTrendingItemsUseCase where Value == [TrendingItem] {}

extension TVFeedViewModel {
    /// The example movies, the first two of them favourited.
    static func preview() -> TVFeedViewModel {
        TVFeedViewModel(
            fetchMoviesUseCase: PreviewUseCase(value: Movie.exampleMovies),
            fetchFavoriteTVShowsUseCase: PreviewUseCase(value: [889_737, 1_100_782])
        )
    }
}

extension HomeDiscoverViewModel {
    /// Every section filled, without artwork so nothing waits on the image CDN.
    static func preview() -> HomeDiscoverViewModel {
        HomeDiscoverViewModel(
            fetchGenresUseCase: PreviewUseCase(value: [
                Genre(id: 28, name: "Action"), Genre(id: 35, name: "Comedy"), Genre(id: 18, name: "Drama"),
            ]),
            fetchTVGenresUseCase: PreviewUseCase(value: [
                Genre(id: 10765, name: "Sci-Fi & Fantasy"), Genre(id: 80, name: "Crime"),
            ]),
            fetchPopularPeopleUseCase: PreviewUseCase(value: [
                PopularPerson(id: 287, name: "Brad Pitt", profilePath: nil, knownForDepartment: "Acting", popularity: 42),
                PopularPerson(id: 1245, name: "Scarlett Johansson", profilePath: nil, knownForDepartment: "Acting", popularity: 38),
            ]),
            fetchTrendingItemsUseCase: PreviewUseCase(value: [
                TrendingItem(id: 693_134, title: "Dune: Part Two", name: nil, posterPath: nil, backdropPath: nil, overview: nil, mediaType: .movie, popularity: 320, voteAverage: 8.2),
                TrendingItem(id: 1399, title: nil, name: "Game of Thrones", posterPath: nil, backdropPath: nil, overview: nil, mediaType: .tv, popularity: 450, voteAverage: 8.5),
            ])
        )
    }
}
#endif
