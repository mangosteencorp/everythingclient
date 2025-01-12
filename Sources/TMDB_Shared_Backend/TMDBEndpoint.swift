import Foundation

public enum TMDBEndpoint {
    
    // Movie Lists
    case popular(page: Int? = nil), topRated(page: Int? = nil), upcoming(page: Int? = nil), nowPlaying(page: Int? = nil), trending(page: Int? = nil)
    
    // Movie Details
    case movieDetail(movie: Int)
    case recommended(movie: Int)
    case similar(movie: Int)
    case videos(movie: Int)
    case credits(movie: Int)
    case review(movie: Int)
    
    // Search
    case searchMovie, searchKeyword, searchPerson
    
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
    case setFavoriteMovie(accountId: String)
    case getFavoriteMovies(accountId: String)
    case getFavoriteTVShows(accountId: String)
    
    // Other
    case genres
    case discover
    
    // Additional Movie Lists
    case topRatedMovies
    
    // Watchlist
    case getWatchlistTVShows(accountId: String)
    
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
        case let .setFavoriteMovie(accountId):
            return "account/\(accountId)/favorite"
        case let .getFavoriteMovies(accountId):
            return "account/\(accountId)/favorite/movies"
        case let .getFavoriteTVShows(accountId):
            return "account/\(accountId)/favorite/tv"
            
        // Other
        case .genres:
            return "genre/movie/list"
        case .discover:
            return "discover/movie"
            
        // Additional Movie Lists
        case .topRatedMovies:
            return "movie/top_rated"
            
        // Watchlist
        case let .getWatchlistTVShows(accountId):
            return "account/\(accountId)/watchlist/tv"
        
        }
    }
    
    func needAuthentication() -> Bool {
        switch self {
        case .accountInfo, .setFavoriteMovie, .getFavoriteMovies, .getFavoriteTVShows, .getWatchlistTVShows, .logOut:
            return true
        default:
            return false
        }
    }
    
    func body() -> Data? {
        return nil
    }
    
    func extraQuery() -> [String: String]? {
        switch self {
        case .authNewSession(let requestToken):
            return ["request_token": requestToken]
        case .movieDetail:
            let languages = Locale.preferredLanguages.joined(separator: ",")
            return [
                "include_image_language": languages,
                "append_to_response": "keywords,images"
            ]
        case .popular(let page), .topRated(let page), .upcoming(let page), .nowPlaying(let page), .trending(let page):
            if let page = page {
                return ["page": String(page)]
            }
            return nil
        default:
            return nil
        }
    }
    
    func httpMethod() -> HTTPMethod {
        switch self {
        case .authNewSession:
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
        case .getFavoriteTVShows, .getWatchlistTVShows: 
            return TVShowListResultModel.self
        case .movieDetail:
            return MovieDetailModel.self
        case .credits:
            return MovieCreditsModel.self
        default:
            throw TMDBAPIError.unsupportedEndpoint
        }
    }
}
