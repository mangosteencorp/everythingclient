import Foundation
public enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
    public func method() -> String {
        return self.rawValue.uppercased()
    }
}
public struct TMDBAPIService {
    static let baseURL = "https://api.themoviedb.org/3"
    let apiKey: String
    let decoder = JSONDecoder()
    let session: URLSession
    let authRepository: AuthRepository
    
    public init(apiKey: String, 
                session: URLSession = .shared,
                authRepository: AuthRepository = DefaultAuthRepository()) {
        self.apiKey = apiKey
        self.session = session
        self.authRepository = authRepository
    }
    
    public func request<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T {
        var components = URLComponents(string: TMDBAPIService.baseURL + "/" + endpoint.path())!
        
        // Add API key to query parameters
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: Locale.preferredLanguages[0])
        ]
        
        if let sessionId = authRepository.getSessionId(), endpoint.needAuthentication() {
            queryItems.append(URLQueryItem(name: "session_id", value: sessionId))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw TMDBAPIError.unsupportedEndpoint
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.httpMethod().method()
        request.httpBody = endpoint.body()
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBAPIError.noResponse
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw TMDBAPIError.jsonDecodingError(error: error)
        }
    }
}

public enum TMDBAPIError: Error {
    case noResponse
    case jsonDecodingError(error: Error)
    case networkError(error: Error)
    case unsupportedEndpoint
}

public enum TMDBEndpoint {
    
    // Movie Lists
    case popular, topRated, upcoming, nowPlaying, trending
    
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
    case authStep3
    case logOut
    case accountInfo
    
    // Favorites
    case setFavoriteMovie(accountId: String)
    case getFavoriteMovies(accountId: String)
    
    // Other
    case genres
    case discover
    
    // Additional Movie Lists
    case topRatedMovies
    
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
        case .authStep3:
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
            
        // Other
        case .genres:
            return "genre/movie/list"
        case .discover:
            return "discover/movie"
            
        // Additional Movie Lists
        case .topRatedMovies:
            return "movie/top_rated"
        
        }
    }
    
    func needAuthentication() -> Bool {
        switch self {
        case .accountInfo, .setFavoriteMovie, .getFavoriteMovies, .logOut:
            return true
        default:
            return false
        }
    }
    
    func body() -> Data? {
        return nil
    }
    
    func httpMethod() -> HTTPMethod {
        return .get
    }
    
    public func returnType() throws -> Decodable.Type {
        switch self {
        case .popular, .nowPlaying, .upcoming: return MovieListResultModel.self
        default:
            throw TMDBAPIError.unsupportedEndpoint
        }
    }
}
