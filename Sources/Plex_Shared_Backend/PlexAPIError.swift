import Foundation

/// Domain failures carry no response bodies, credentials, or user-facing strings.
/// Transport and DecodingError failures retain their original types.
public enum PlexAPIError: Error, Equatable, Sendable {
    case invalidConfiguration
    case invalidPath
    case invalidPagination
    case nonHTTPResponse
    case httpStatus(Int)
    case metadataNotFound
    case noDownloadableMedia
    case unavailablePart(String)
    case pinExpired
}
