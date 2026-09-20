import Foundation

/// The two calls the feature view models actually make on `TMDBAPIService`.
///
/// `TMDBAPIService` is a concrete struct that owns a `URLSession`, so anything depending on it
/// directly can only be exercised by standing up a fake network. Depending on this protocol instead
/// lets a feature module inject a plain in-memory double and assert on the endpoints it asked for.
public protocol TMDBAPIRequesting {
    func request<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T
    func request<T: Decodable>(_ endpoint: TMDBEndpoint) async -> Result<T, TMDBAPIError>
}

extension TMDBAPIService: TMDBAPIRequesting {}
