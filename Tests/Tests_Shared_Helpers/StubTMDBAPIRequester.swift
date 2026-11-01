import Foundation
import TMDB_Shared_Backend

/// In-memory stand-in for `TMDBAPIService`, keyed by `TMDBEndpoint.path()`.
///
/// Feature view models can be driven end to end with it: seed a response per endpoint, let the view
/// model run, then assert on `requestedPaths` to check *which* endpoints it asked for and in what
/// order. An endpoint with no seeded response fails with `.notFound(path:)`, so a view model that
/// calls something unexpected shows up as a failing test rather than a silent success.
public final class StubTMDBAPIRequester: TMDBAPIRequesting, @unchecked Sendable {
    public enum StubError: Error, LocalizedError {
        case notFound(path: String)
        case typeMismatch(path: String, expected: String)
        case stubbed(message: String)

        public var errorDescription: String? {
            switch self {
            case let .notFound(path):
                return "no stubbed response for \(path)"
            case let .typeMismatch(path, expected):
                return "stubbed response for \(path) is not a \(expected)"
            case let .stubbed(message):
                return message
            }
        }
    }

    /// View models fire requests concurrently (`async let`), so every access to the mutable state
    /// below goes through this lock — that is what makes the `@unchecked Sendable` honest.
    private let lock = NSLock()
    private var responses: [String: Result<Any, Error>] = [:]
    private var _requestedPaths: [String] = []
    private var _requestedEndpoints: [TMDBEndpoint] = []

    public var requestedPaths: [String] { lock.withLock { _requestedPaths } }
    /// The endpoints themselves, for assertions about the query parameters a caller built and
    /// not just the path it hit.
    public var requestedEndpoints: [TMDBEndpoint] { lock.withLock { _requestedEndpoints } }

    public init() {}

    // MARK: - Seeding

    public func stub<T>(_ endpoint: TMDBEndpoint, with value: T) {
        lock.withLock { responses[endpoint.path()] = .success(value) }
    }

    public func stub(_ endpoint: TMDBEndpoint, failingWith error: Error) {
        lock.withLock { responses[endpoint.path()] = .failure(error) }
    }

    /// Convenience for the common "the request failed with this message" case.
    public func stub(_ endpoint: TMDBEndpoint, failingWithMessage message: String) {
        stub(endpoint, failingWith: StubError.stubbed(message: message))
    }

    // MARK: - TMDBAPIRequesting

    public func request<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T {
        let path = endpoint.path()
        let response = lock.withLock {
            _requestedPaths.append(path)
            _requestedEndpoints.append(endpoint)
            return responses[path]
        }

        guard let response else { throw StubError.notFound(path: path) }
        let value = try response.get()
        guard let typed = value as? T else {
            throw StubError.typeMismatch(path: path, expected: String(describing: T.self))
        }
        return typed
    }

    public func request<T: Decodable>(_ endpoint: TMDBEndpoint) async -> Result<T, TMDBAPIError> {
        do {
            let value: T = try await request(endpoint)
            return .success(value)
        } catch let error as TMDBAPIError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error: error))
        }
    }
}
