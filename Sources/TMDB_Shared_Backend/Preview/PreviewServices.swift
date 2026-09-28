import Foundation

#if DEBUG
/// Answers `TMDBAPIRequesting` from memory, so a preview that loads its own data renders offline
/// and the same on every run.
///
/// Responses are keyed by `TMDBEndpoint.path()`. An endpoint with nothing seeded fails like a
/// dropped connection, which is also how a preview shows its error state.
public struct PreviewTMDBAPIRequester: TMDBAPIRequesting {
    private let responses: [String: Any]

    public init(_ responses: KeyValuePairs<TMDBEndpoint, Any> = [:]) {
        self.responses = Dictionary(responses.map { ($0.key.path(), $0.value) }) { first, _ in first }
    }

    public func request<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T {
        guard let value = responses[endpoint.path()] as? T else {
            throw URLError(.notConnectedToInternet)
        }
        return value
    }

    public func request<T: Decodable>(_ endpoint: TMDBEndpoint) async -> Result<T, TMDBAPIError> {
        do {
            return try await .success(request(endpoint))
        } catch {
            return .failure(.networkError(error: error))
        }
    }
}

/// A TMDB account that is already signed in or out, and never opens the web sign-in sheet.
public struct PreviewAuthenticationService: AuthenticationServiceProtocol {
    public let isAuthenticated: Bool

    public init(isAuthenticated: Bool) {
        self.isAuthenticated = isAuthenticated
    }

    public func getRequestToken() async throws -> String {
        throw URLError(.notConnectedToInternet)
    }

    public func createSession(requestToken: String) async throws -> String {
        throw URLError(.notConnectedToInternet)
    }

    public func signOut() async throws {}

    public func getAuthenticationURL(with token: String) throws -> URL {
        throw URLError(.notConnectedToInternet)
    }
}
#endif
