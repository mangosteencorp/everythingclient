import Foundation

/// Domain failures carry no response bodies, credentials, or user-facing strings.
/// Transport and DecodingError failures retain their original types.
public enum PlexAPIError: Error, Equatable, Sendable {
    /// A base URL, token, identity field or header value is unusable or unsafe.
    case invalidConfiguration
    /// A path or ID would leave the configured server: an external host, traversal, or an injected token.
    case invalidPath
    /// A negative start or a non-positive page size.
    case invalidPagination
    /// The transport returned something other than an HTTP response.
    case nonHTTPResponse
    /// The server answered with a non-2xx status code. The body is deliberately dropped.
    case httpStatus(Int)
    /// The server's response did not contain the requested item.
    case metadataNotFound
    /// No media version has an available, keyed file to download or play.
    case noDownloadableMedia
    /// A required file part is missing on the server or has no key; the associated value is the part ID or index.
    case unavailablePart(String)
    /// The sign-in PIN expired or was removed before it was authorized.
    case pinExpired
    /// None of the server's advertised connections answered as the expected server; from `connectBest`, no server did.
    case noReachableServer
    /// `connectBest` reached servers, but none offered the requested library types.
    case noServerWithContent
    /// Offline mode is on (or the network failed) and nothing was cached for this request.
    case offline
    /// The server's machine identifier is unknown, so a `server://` URI cannot be built.
    case missingMachineIdentifier
}
