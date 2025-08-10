import Foundation
// swiftlint:disable type_body_length
public enum TMDBEndpoint {
    // Movie Lists
    case popular(page: Int? = nil), topRated(page: Int? = nil), upcoming(page: Int? = nil), nowPlaying(
        page: Int? = nil
    ),
        trending(page: Int? = nil), trendingAll(page: Int? = nil)

    // Movie Details
    case movieDetail(movie: Int)
    case recommended(movie: Int)
    case similar(movie: Int)
    case videos(movie: Int)
    case credits(movie: Int)
    case review(movie: Int)

    // Search
    case searchMovie(
        query: String,
        includeAdult: Bool? = nil,
        language: String? = nil,
        primaryReleaseYear: String? = nil,
        page: Int? = nil,
        region: String? = nil,
        year: String? = nil
    )
    case searchTVShows(
        query: String,
        includeAdult: Bool? = nil,
        language: String? = nil,
        firstAirDateYear: String? = nil,
        page: Int? = nil,
        region: String? = nil,
        year: String? = nil
    )
    case searchKeyword, searchPerson

    // Person
    case popularPersons
    case personDetail(person: Int)
    case personMovieCredits(person: Int)
    case personImages(person: Int)

    // Authentication & Account
    case authStep1
    case authNewSession(requestToken: String)
    case logOut
    case accountInfo

    // Favorites
    case setFavoriteMovie(accountId: String, movieId: Int, favorite: Bool)
    case setFavoriteTVShow(accountId: String, tvShowId: Int, favorite: Bool)
    case getFavoriteMovies(accountId: String)
    case getFavoriteTVShows(accountId: String)

    // Other
    case genres
    case discoverMovie(
        keywords: Int? = nil,
        cast: Int? = nil,
        genres: [Int]? = nil,
        watchProviders: [Int]? = nil,
        watchRegion: String? = nil,
        includeAdult: Bool? = nil,
        language: String? = nil,
        page: Int? = nil
    )

    // Additional Movie Lists
    case topRatedMovies

    // Watchlist
    case getWatchlistTVShows(accountId: String)

    // TV Shows
    case tvAiringToday(page: Int? = nil)
    case tvOnTheAir(page: Int? = nil)
    case airingTodayTVShows(page: Int? = nil)
    case onTheAirTVShows(page: Int? = nil)

    // TV Show Details
    case tvShowDetail(show: Int)

    // swiftlint:disable cyclomatic_complexity
    func path() -> String {
        switch self {
        // Movie Lists
        case .popular:
            return "movie/popular"
        case .topRated:
            return "movie/top_rated"
        case .upcoming:
            return "movie/upcoming"
        case .nowPlaying:
            return "movie/now_playing"
        case .trending:
            return "trending/movie/day"
        case .trendingAll:
            return "trending/all/day"
        // Movie Details
        case let .movieDetail(movie):
            return "movie/\(movie)"
        case let .videos(movie):
            return "movie/\(movie)/videos"
        case let .credits(movie):
            return "movie/\(movie)/credits"
        case let .review(movie):
            return "movie/\(movie)/reviews"
        case let .recommended(movie):
            return "movie/\(movie)/recommendations"
        case let .similar(movie):
            return "movie/\(movie)/similar"
        // Person
        case .popularPersons:
            return "person/popular"
        case let .personDetail(person):
            return "person/\(person)"
        case let .personMovieCredits(person):
            return "person/\(person)/movie_credits"
        case let .personImages(person):
            return "person/\(person)/images"
        // Search
        case .searchMovie:
            return "search/movie"
        case .searchTVShows:
            return "search/tv"
        case .searchKeyword:
            return "search/keyword"
        case .searchPerson:
            return "search/person"
        // Authentication & Account
        case .authStep1:
            return "authentication/token/new"
        case .authNewSession:
            return "authentication/session/new"
        case .logOut:
            return "authentication/session"
        case .accountInfo:
            return "account"
        // Favorites
        case let .setFavoriteMovie(accountId, _, _):
            return "account/\(accountId)/favorite"
        case let .setFavoriteTVShow(accountId, _, _):
            return "account/\(accountId)/favorite"
        case let .getFavoriteMovies(accountId):
            return "account/\(accountId)/favorite/movies"
        case let .getFavoriteTVShows(accountId):
            return "account/\(accountId)/favorite/tv"
        // Other
        case .genres:
            return "genre/movie/list"
        case .discoverMovie:
            return "discover/movie"
        // Additional Movie Lists
        case .topRatedMovies:
            return "movie/top_rated"
        // Watchlist
        case let .getWatchlistTVShows(accountId):
            return "account/\(accountId)/watchlist/tv"
        // TV Shows
        case .tvAiringToday, .airingTodayTVShows:
            return "tv/airing_today"
        case .tvOnTheAir, .onTheAirTVShows:
            return "tv/on_the_air"
        // TV Show Details
        case let .tvShowDetail(show):
            return "tv/\(show)"
        }
    }

    // swiftlint:enable cyclomatic_complexity
    func needAuthentication() -> Bool {
        switch self {
        case .accountInfo, .setFavoriteMovie, .setFavoriteTVShow, .getFavoriteMovies, .getFavoriteTVShows, .getWatchlistTVShows, .logOut:
            return true
        default:
            return false
        }
    }

    func body() -> Data? {
        switch self {
        case let .setFavoriteMovie(_, movieId, favorite):
            let body = [
                "media_type": "movie",
                "media_id": movieId,
                "favorite": favorite,
            ] as [String: Any]
            return try? JSONSerialization.data(withJSONObject: body)
        case let .setFavoriteTVShow(_, tvShowId, favorite):
            let body = [
                "media_type": "tv",
                "media_id": tvShowId,
                "favorite": favorite,
            ] as [String: Any]
            return try? JSONSerialization.data(withJSONObject: body)
        default:
            return nil
        }
    }

    func extraQuery() -> [String: String]? {
        switch self {
        case let .authNewSession(requestToken):
            return ["request_token": requestToken]
        case .movieDetail:
            let languages = Locale.preferredLanguages.joined(separator: ",")
            return [
                "include_image_language": languages,
                "append_to_response": "keywords,images",
            ]
        case let .popular(page), let .topRated(page), let .upcoming(page), let .nowPlaying(page), let .trending(page), let .trendingAll(page):
            if let page = page {
                return ["page": String(page)]
            }
            return nil
        case let .searchMovie(query, includeAdult, language, primaryReleaseYear, page, region, year):
            return buildSearchMovieParams(
                query: query,
                includeAdult: includeAdult,
                language: language,
                primaryReleaseYear: primaryReleaseYear,
                page: page,
                region: region,
                year: year
            )
        case let .searchTVShows(query, includeAdult, language, firstAirDateYear, page, region, year):
            return buildSearchTVShowsParams(
                query: query,
                includeAdult: includeAdult,
                language: language,
                firstAirDateYear: firstAirDateYear,
                page: page,
                region: region,
                year: year
            )
        case let .discoverMovie(keywords, cast, genres, watchProviders, watchRegion, includeAdult, language, page):
            return buildDiscoverMovieParams(
                keywords: keywords,
                cast: cast,
                genres: genres,
                watchProviders: watchProviders,
                watchRegion: watchRegion,
                includeAdult: includeAdult,
                language: language,
                page: page
            )
        case let .tvAiringToday(page), let .tvOnTheAir(page), let .airingTodayTVShows(page), let .onTheAirTVShows(page):
            if let page = page {
                return ["page": String(page)]
            }
            return nil
        default:
            return nil
        }
    }

    // MARK: - Private Helper Methods

    private func buildSearchMovieParams(
        query: String,
        includeAdult: Bool?,
        language: String?,
        primaryReleaseYear: String?,
        page: Int?,
        region: String?,
        year: String?
    ) -> [String: String] {
        var params = ["query": query]

        if let includeAdult = includeAdult {
            params["include_adult"] = includeAdult ? "true" : "false"
        }
        if let language = language {
            params["language"] = language
        }
        if let primaryReleaseYear = primaryReleaseYear {
            params["primary_release_year"] = primaryReleaseYear
        }
        if let page = page {
            params["page"] = String(page)
        }
        if let region = region {
            params["region"] = region
        }
        if let year = year {
            params["year"] = year
        }

        return params
    }

    private func buildSearchTVShowsParams(
        query: String,
        includeAdult: Bool?,
        language: String?,
        firstAirDateYear: String?,
        page: Int?,
        region: String?,
        year: String?
    ) -> [String: String] {
        var params = ["query": query]

        if let includeAdult = includeAdult {
            params["include_adult"] = includeAdult ? "true" : "false"
        }
        if let language = language {
            params["language"] = language
        }
        if let firstAirDateYear = firstAirDateYear {
            params["first_air_date_year"] = firstAirDateYear
        }
        if let page = page {
            params["page"] = String(page)
        }
        if let region = region {
            params["region"] = region
        }
        if let year = year {
            params["year"] = year
        }

        return params
    }

    private func buildDiscoverMovieParams(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        includeAdult: Bool?,
        language: String?,
        page: Int?
    ) -> [String: String] {
        var params: [String: String] = [:]

        if let keywords = keywords {
            params["with_keywords"] = String(keywords)
        }
        if let cast = cast {
            params["with_cast"] = String(cast)
        }
        if let genres = genres, !genres.isEmpty {
            params["with_genres"] = genres.map(String.init).joined(separator: ",")
        }
        if let watchProviders = watchProviders, !watchProviders.isEmpty {
            params["with_watch_providers"] = watchProviders.map(String.init).joined(separator: ",")
        }
        if let watchRegion = watchRegion {
            params["watch_region"] = watchRegion
        }
        if let includeAdult = includeAdult {
            params["include_adult"] = includeAdult ? "true" : "false"
        }
        if let language = language {
            params["language"] = language
        }
        if let page = page {
            params["page"] = String(page)
        }

        return params
    }

    func httpMethod() -> HTTPMethod {
        switch self {
        case .authNewSession, .setFavoriteMovie, .setFavoriteTVShow:
            return .post
        default:
            return .get
        }
    }

    public func returnType() throws -> Decodable.Type {
        switch self {
        case .popular, .nowPlaying, .upcoming, .getFavoriteMovies:
            return MovieListResultModel.self
        case .accountInfo:
            return AccountInfoModel.self
        case .setFavoriteMovie, .setFavoriteTVShow:
            return FavoriteResponse.self
        case .getFavoriteTVShows, .getWatchlistTVShows:
            return TVShowListResultModel.self
        case .movieDetail:
            return MovieDetailModel.self
        case .credits:
            return MovieCreditsModel.self
        case .searchMovie:
            return MovieListResultModel.self
        case .searchTVShows:
            return TVShowListResultModel.self
        case .discoverMovie:
            return MovieListResultModel.self
        case .tvAiringToday, .tvOnTheAir, .airingTodayTVShows, .onTheAirTVShows:
            return TVShowListResultModel.self
        case .tvShowDetail:
            return TVShowDetailModel.self
        case .genres:
            return GenreListModel.self
        case .popularPersons:
            return PersonListResultModel.self
        case .trendingAll:
            return TrendingAllResultModel.self
        default:
            throw TMDBAPIError.unsupportedEndpoint
        }
    }
}

// swiftlint:enable type_body_length
