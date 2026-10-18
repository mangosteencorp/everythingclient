import Foundation

/// A page request, sent as `X-Plex-Container-Start` and `X-Plex-Container-Size`.
/// Continue from the returned `offset` plus the item count until it reaches `totalSize`.
public struct PlexPagination: Sendable, Equatable, Hashable {
    /// Zero-based index of the first item.
    public let start: Int
    /// Maximum number of items to return.
    public let size: Int

    /// - Throws: `PlexAPIError.invalidPagination` for a negative start or a non-positive size.
    public init(start: Int = 0, size: Int = 100) throws {
        guard start >= 0, size > 0 else { throw PlexAPIError.invalidPagination }
        self.start = start
        self.size = size
    }

    var query: [URLQueryItem] {
        [
            URLQueryItem(name: "X-Plex-Container-Start", value: String(start)),
            URLQueryItem(name: "X-Plex-Container-Size", value: String(size)),
        ]
    }
}

/// Library browsing options. `filters` use the `filter` names and values a section advertises,
/// for example `["genre": "12", "unwatched": "1"]`; `sort` uses a sort key such as `titleSort` or `addedAt:desc`.
public struct PlexLibraryQuery: Sendable, Equatable, Hashable {
    /// Plex metadata type: 1 movie, 2 show, 3 season, 4 episode.
    public var type: Int?
    /// A sort key from `sorts(sectionID:)`, or its `descKey` for descending order.
    public var sort: String?
    /// Filter values keyed by a filter's `filter` name; a value is a filter value's `key`.
    public var filters: [String: String]

    /// Creates a query; the defaults list everything in the server's default order.
    public init(type: Int? = nil, sort: String? = nil, filters: [String: String] = [:]) {
        self.type = type
        self.sort = sort
        self.filters = filters
    }

    var items: [URLQueryItem] {
        [type.map { URLQueryItem(name: "type", value: String($0)) }, sort.map { URLQueryItem(name: "sort", value: $0) }]
            .compactMap { $0 } + filters.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
}

/// A Plex Media Server request: method, server-relative path and query. Paths are resolved
/// against the configured origin (including any proxy prefix); credentials travel in headers.
public struct PlexEndpoint: Sendable, Equatable {
    /// The HTTP method.
    public let method: PlexHTTPMethod
    /// The server-relative path, which may carry a server-provided query.
    public let path: String
    /// Additional query items.
    public let query: [URLQueryItem]

    /// Describes a request; nothing is validated until `makeRequest(configuration:)`.
    public init(_ method: PlexHTTPMethod = .get, _ path: String, query: [URLQueryItem] = []) {
        self.method = method
        self.path = path
        self.query = query
    }

    /// Resolves the endpoint against a server and adds identity and token headers.
    /// - Throws: `PlexAPIError.invalidPath` when the path or query would leave the server or inject a token.
    public func makeRequest(configuration: PlexServerConfiguration) throws -> URLRequest {
        var request = try configuration.request(path: path, query: query)
        request.httpMethod = method.rawValue
        return request
    }
}

extension PlexEndpoint {
    static func flags(_ names: String...) -> [URLQueryItem] { names.map { URLQueryItem(name: $0, value: "1") } }

    /// `GET /library/sections`: the server's library sections.
    public static let libraries = PlexEndpoint(.get, "/library/sections")

    /// `"shared"` lists items individually shared with this account.
    public static func libraryItems(
        sectionID: String, page: PlexPagination? = nil, query: PlexLibraryQuery = PlexLibraryQuery()
    ) throws -> PlexEndpoint {
        let path = sectionID == "shared" ? "/library/shared/all" : "/library/sections/\(try PlexURLBuilder.segment(sectionID))/all"
        return PlexEndpoint(.get, path, query: query.items + (page?.query ?? []))
    }

    /// Includes markers, chapters, file availability, streams and the next on-deck episode.
    public static func metadata(ratingKey: String) throws -> PlexEndpoint {
        PlexEndpoint(.get, "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))", query: flags(
            "includeMarkers", "includeChapters", "checkFiles", "includeStreams", "includeOnDeck"
        ))
    }

    /// `GET /library/metadata/{id}/children`: seasons of a show or episodes of a season.
    public static func children(ratingKey: String, page: PlexPagination? = nil) throws -> PlexEndpoint {
        PlexEndpoint(.get, "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))/children",
                     query: (page?.query ?? []) + flags("includeStreams"))
    }

    /// Plezy uses /grandchildren for playable show/season descendants because /allLeaves can be empty for seasons.
    public static func grandchildren(ratingKey: String, page: PlexPagination? = nil) throws -> PlexEndpoint {
        PlexEndpoint(.get, "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))/grandchildren",
                     query: (page?.query ?? []) + flags("includeStreams"))
    }

    /// Hits arrive as `SearchResult[].Metadata` and are flattened into `PlexMediaContainer.metadata`.
    public static func search(query term: String, page: PlexPagination? = nil) -> PlexEndpoint {
        PlexEndpoint(.get, "/library/search", query: (page?.query ?? []) + [
            URLQueryItem(name: "query", value: term),
            URLQueryItem(name: "searchTypes", value: "movies,tv"),
        ] + flags("includeCollections"))
    }

    /// `GET /library/recentlyAdded`: newest items across libraries.
    public static func recentlyAdded(page: PlexPagination? = nil) -> PlexEndpoint {
        PlexEndpoint(.get, "/library/recentlyAdded", query: page?.query ?? [])
    }

    /// `GET /library/metadata/{id}/extras`: trailers, featurettes and other clips.
    public static func extras(ratingKey: String) throws -> PlexEndpoint {
        PlexEndpoint(.get, "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))/extras")
    }
}
