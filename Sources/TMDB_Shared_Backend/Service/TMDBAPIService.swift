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
        
        // Add extra queries from endpoint if available
        if let extraQueries = endpoint.extraQuery() {
            queryItems.append(contentsOf: extraQueries.map { 
                URLQueryItem(name: $0.key, value: $0.value)
            })
        }
        
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
        debugPrint(request.curlString)
        let (data, response) = try await session.data(for: request)
        
        guard let _ = response as? HTTPURLResponse else {
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
    case authNewSession(requestToken: String)
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
    
    func extraQuery() -> [String: String]? {
        switch self {
        case .authNewSession(let requestToken):
            return ["request_token": requestToken]
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
        case .popular, .nowPlaying, .upcoming: return MovieListResultModel.self
        default:
            throw TMDBAPIError.unsupportedEndpoint
        }
    }
}
