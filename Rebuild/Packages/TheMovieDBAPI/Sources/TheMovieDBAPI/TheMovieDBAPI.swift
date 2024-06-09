import Foundation
public struct TheMovieDBAPIService {
    let baseURL = URL(string: "https://api.themoviedb.org/3")!
    let apiKey = "1d9b898a212ea52e283351e521e17871"
    let decoder = JSONDecoder()
    public static let shared = TheMovieDBAPIService()
    public enum Endpoint {
        case nowPlaying
        func path() -> String {
            switch self {
            case .nowPlaying:
                return "movie/now_playing"
            }
        }
    }
    public enum APIError: Error {
        case noResponse
        case jsonDecodingError(error: Error)
        case networkError(error: Error)
    }
    @available(iOS 13.0.0, *)
    func load<T: Codable>(endpoint: Endpoint) async -> Result<T,APIError> {
        let queryURL = baseURL.appendingPathComponent(endpoint.path())
        var components = URLComponents(url: queryURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: Locale.preferredLanguages.first),
        ]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try decoder.decode(T.self, from: data)
            return .success(result)
        } catch {
            if let decodingError = error as? DecodingError {
                return .failure(.jsonDecodingError(error: decodingError))
            } else {
                return .failure(.networkError(error: error))
            }
        }
    }
    @available(iOS 13.0.0, *)
    public func loadNowPlayingMovies() async -> Result<MovieResponse,APIError> {
        return await load(endpoint: .nowPlaying)
    }
    public func buildImageUrl(quality: TMDBImageQuality = .w500, imagePath: ImagePath) -> URL? {
        let strImageUrl = "https://image.tmdb.org/t/p/\(quality)\(imagePath)"
        return URL.init(string: strImageUrl)
    }
}
