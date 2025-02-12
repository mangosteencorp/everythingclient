import Foundation

public enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
    public func method() -> String {
        return rawValue.uppercased()
    }
}

public struct TMDBAPIService {
    static let baseURL = "https://api.themoviedb.org/3"
    let apiKey: String
    let decoder = JSONDecoder()
    let session: URLSession
    let authRepository: AuthRepository

    public init(
        apiKey: String,
        session: URLSession = .shared,
        authRepository: AuthRepository = DefaultAuthRepository()
    ) {
        self.apiKey = apiKey
        self.session = session
        self.authRepository = authRepository
    }

    public func request<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T {
        var components = URLComponents(string: TMDBAPIService.baseURL + "/" + endpoint.path())!

        // Add API key to query parameters
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: Locale.preferredLanguages[0]),
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

    public func request<T: Decodable>(_ endpoint: TMDBEndpoint) async -> Result<T, TMDBAPIError> {
        do {
            let result: T = try await request(endpoint)
            return .success(result)
        } catch {
            return .failure(error as! TMDBAPIError)
        }
    }
}
