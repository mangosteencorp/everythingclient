import Foundation

public struct PlexPagination: Sendable, Equatable {
    public let start: Int
    public let size: Int

    public init(start: Int = 0, size: Int = 100) throws {
        guard start >= 0, size > 0 else { throw PlexAPIError.invalidPagination }
        self.start = start
        self.size = size
    }

    var query: [URLQueryItem] {
        [URLQueryItem(name: "X-Plex-Container-Start", value: String(start)),
         URLQueryItem(name: "X-Plex-Container-Size", value: String(size))]
    }
}

/// Read-only Plex Media Server endpoints verified against Plezy's request behavior.
public enum PlexEndpoint: Sendable, Equatable {
    case libraries
    case libraryItems(sectionID: String, page: PlexPagination? = nil)
    case metadata(ratingKey: String)
    case children(ratingKey: String, page: PlexPagination? = nil)
    case grandchildren(ratingKey: String, page: PlexPagination? = nil)

    public func makeRequest(configuration: PlexServerConfiguration) throws -> URLRequest {
        let path: String
        var query: [URLQueryItem] = []
        switch self {
        case .libraries:
            path = "/library/sections"
        case let .libraryItems(sectionID, page):
            path = sectionID == "shared" ? "/library/shared/all" : "/library/sections/\(try PlexURLBuilder.segment(sectionID))/all"
            query = page?.query ?? []
        case let .metadata(ratingKey):
            path = "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))"
            query = ["includeMarkers", "includeChapters", "checkFiles", "includeStreams"].map { URLQueryItem(name: $0, value: "1") }
        case let .children(ratingKey, page):
            path = "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))/children"
            query = (page?.query ?? []) + [URLQueryItem(name: "includeStreams", value: "1")]
        case let .grandchildren(ratingKey, page):
            path = "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))/grandchildren"
            query = (page?.query ?? []) + [URLQueryItem(name: "includeStreams", value: "1")]
        }
        return try configuration.request(path: path, query: query)
    }
}
