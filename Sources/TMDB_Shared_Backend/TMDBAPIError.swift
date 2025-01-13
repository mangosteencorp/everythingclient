import Foundation
public enum TMDBAPIError: Error {
    case noResponse
    case jsonDecodingError(error: Error)
    case networkError(error: Error)
    case unsupportedEndpoint
}
