import Foundation

public enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
    public func method() -> String {
        rawValue.uppercased()
    }
}

public struct TMDBAPIService {
    static let baseURL = "https://api.themoviedb.org/3"
    let apiKey: String
    let decoder = JSONDecoder()
    let session: URLSession
    let authRepository: AuthRepository
    let urlCacheOptions: TMDBURLCacheOptions

    public init(
        apiKey: String,
        session: URLSession? = nil,
        authRepository: AuthRepository = DefaultAuthRepository(),
        urlCacheOptions: TMDBURLCacheOptions = .disabled
    ) {
        self.apiKey = apiKey
        self.authRepository = authRepository
        self.urlCacheOptions = urlCacheOptions
        if let session {
            self.session = session
        } else {
            self.session = Self.makeSession(urlCacheEnabled: urlCacheOptions.isEnabled)
        }
    }

    public func request<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T {
        var components = URLComponents(string: TMDBAPIService.baseURL + "/" + endpoint.path())!

        // Add API key to query parameters
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: Locale.preferredLanguages[0]),
        ]

        // Add extra queries from endpoint if available.
        // An endpoint that names a parameter we already defaulted (e.g. `language`) wins:
        // sending the same key twice makes TMDB reject the whole request with
        // status_code 5 "Invalid parameters".
        if let extraQueries = endpoint.extraQuery() {
            for (key, value) in extraQueries {
                if let index = queryItems.firstIndex(where: { $0.name == key }) {
                    queryItems[index] = URLQueryItem(name: key, value: value)
                } else {
                    queryItems.append(URLQueryItem(name: key, value: value))
                }
            }
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
        request.cachePolicy = cachePolicy(for: endpoint)

        if endpoint.body() != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        debugPrint(request.curlString)
        let (data, response) = try await session.data(for: request)

        guard let _ = response as? HTTPURLResponse else {
            throw TMDBAPIError.noResponse
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            debugPrint(String(data: data, encoding: .utf8) ?? "unable to decode response body")
            throw TMDBAPIError.jsonDecodingError(error: error)
        }
    }

    public func request<T: Decodable>(_ endpoint: TMDBEndpoint) async -> Result<T, TMDBAPIError> {
        do {
            let result: T = try await request(endpoint)
            return .success(result)
        } catch let error as TMDBAPIError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error: error))
        }
    }

    /// GET + unauthenticated requests use URL cache when options are enabled; otherwise bypass.
    func cachePolicy(for endpoint: TMDBEndpoint) -> URLRequest.CachePolicy {
        if shouldUseURLCache(for: endpoint) {
            return .returnCacheDataElseLoad
        }
        return .reloadIgnoringLocalCacheData
    }

    func shouldUseURLCache(for endpoint: TMDBEndpoint) -> Bool {
        urlCacheOptions.isEnabled
            && endpoint.httpMethod() == .get
            && !endpoint.needAuthentication()
    }

    private static func makeSession(urlCacheEnabled: Bool) -> URLSession {
        let configuration = URLSessionConfiguration.default
        if urlCacheEnabled {
            configuration.urlCache = URLCache(
                memoryCapacity: 20 * 1024 * 1024,
                diskCapacity: 100 * 1024 * 1024,
                directory: nil
            )
            configuration.requestCachePolicy = .returnCacheDataElseLoad
        } else {
            configuration.urlCache = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        }
        return URLSession(configuration: configuration)
    }
}
