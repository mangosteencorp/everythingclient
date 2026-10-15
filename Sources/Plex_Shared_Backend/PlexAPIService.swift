import Foundation

/// Browsing: sections, items with sort/filter, metadata, descendants, search, folders and people.
public protocol PlexLibraryServing: Sendable {
    /// The server's library sections.
    func libraries() async throws -> [PlexLibrary]
    /// One page of a section's items, sorted and filtered by `query`. Pass `"shared"` for items shared with this account.
    func items(sectionID: String, page: PlexPagination?, query: PlexLibraryQuery) async throws -> PlexMediaContainer
    /// Full details for one item, including media versions, streams, markers, cast and the next On Deck episode.
    /// - Throws: `PlexAPIError.metadataNotFound` when the response doesn't contain the item.
    func metadata(ratingKey: String) async throws -> PlexMetadata
    /// Direct children: a show's seasons, a season's episodes.
    func children(ratingKey: String, page: PlexPagination?) async throws -> PlexMediaContainer
    /// All playable descendants of a show, across seasons.
    func grandchildren(ratingKey: String, page: PlexPagination?) async throws -> PlexMediaContainer
    /// Server-wide search across movies, shows and collections.
    func search(query: String, page: PlexPagination?) async throws -> PlexMediaContainer
    /// The newest items across all libraries.
    func recentlyAdded(page: PlexPagination?) async throws -> PlexMediaContainer
    /// Trailers, featurettes and other clips attached to an item.
    func extras(ratingKey: String) async throws -> PlexMediaContainer
    /// Filter fields a section supports; each `filter` is a `PlexLibraryQuery.filters` key.
    func filters(sectionID: String) async throws -> [PlexDirectory]
    /// Sort options a section supports; use `key` or `descKey` as `PlexLibraryQuery.sort`.
    func sorts(sectionID: String) async throws -> [PlexDirectory]
    /// Leading characters with item counts, for an alphabet jump bar.
    func firstCharacters(sectionID: String, query: PlexLibraryQuery) async throws -> [PlexDirectory]
    /// A section's top-level folders as `directories`.
    func folders(sectionID: String) async throws -> PlexMediaContainer
    /// Everything an actor or crew member appears in.
    func personMedia(personID: String, page: PlexPagination?) async throws -> PlexMediaContainer
    /// Follows a server-returned key: filter values, folder children, a hub's full list.
    func container(key: String, page: PlexPagination?) async throws -> PlexMediaContainer
    /// Fetches an item and plans authenticated requests for its original file parts and external subtitles.
    func downloadPlan(ratingKey: String, mediaIndex: Int, selection: PlexDownloadPartSelection) async throws
        -> PlexDownloadPlan
}

/// Server-scoped service analogous to TMDBAPIService; transport and feature-facing APIs are mockable.
/// Wrap the transport in `PlexCachingTransport` for Plezy-style offline reads.
public struct PlexAPIService: PlexLibraryServing {
    /// The server this service talks to.
    public let configuration: PlexServerConfiguration
    let executor: PlexRequestExecutor

    /// Creates a service for one server.
    /// - Parameters:
    ///   - configuration: The server origin, token and client identity.
    ///   - transport: Performs the HTTP calls. Use `PlexCachingTransport` for offline support, or a stub in tests.
    public init(configuration: PlexServerConfiguration, transport: any PlexHTTPTransport = PlexURLSessionTransport()) {
        self.configuration = configuration
        executor = PlexRequestExecutor(transport: transport)
    }

    /// Sends any endpoint and decodes its JSON into `Response`.
    /// - Throws: `PlexAPIError.httpStatus` for non-2xx responses, or `DecodingError` for unexpected JSON.
    public func request<Response: Decodable & Sendable>(_ endpoint: PlexEndpoint) async throws -> Response {
        try await executor.decode(Response.self, request: endpoint.makeRequest(configuration: configuration))
    }

    func container(_ endpoint: PlexEndpoint) async throws -> PlexMediaContainer {
        let response: PlexResponse = try await request(endpoint)
        return response.mediaContainer
    }

    /// Mutations: Plex replies with an empty body, XML, or a container nobody needs.
    func send(_ endpoint: PlexEndpoint) async throws {
        _ = try await executor.execute(endpoint.makeRequest(configuration: configuration))
    }

    /// Standard library sections. Individually shared items are listed with `items(sectionID: "shared")`.
    public func libraries() async throws -> [PlexLibrary] {
        try await container(.libraries).libraries
    }

    /// `GET /library/sections/{id}/all` with `type`, `sort` and filter query items.
    public func items(
        sectionID: String, page: PlexPagination? = nil, query: PlexLibraryQuery = PlexLibraryQuery()
    ) async throws -> PlexMediaContainer {
        try await container(.libraryItems(sectionID: sectionID, page: page, query: query))
    }

    /// `GET /library/metadata/{id}?includeMarkers=1&includeChapters=1&checkFiles=1&includeStreams=1&includeOnDeck=1`.
    public func metadata(ratingKey: String) async throws -> PlexMetadata {
        guard let item = try await container(.metadata(ratingKey: ratingKey)).metadata.first(where: { $0.ratingKey == ratingKey })
        else { throw PlexAPIError.metadataNotFound }
        return item
    }

    /// `GET /library/metadata/{id}/children`.
    public func children(ratingKey: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        try await container(.children(ratingKey: ratingKey, page: page))
    }

    /// `GET /library/metadata/{id}/grandchildren`. Plezy prefers it to `/allLeaves`, which can be empty for seasons.
    public func grandchildren(ratingKey: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        try await container(.grandchildren(ratingKey: ratingKey, page: page))
    }

    /// `GET /library/search?searchTypes=movies,tv`; hits are unwrapped from `SearchResult`.
    public func search(query: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        try await container(.search(query: query, page: page))
    }

    /// `GET /library/recentlyAdded`.
    public func recentlyAdded(page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        try await container(.recentlyAdded(page: page))
    }

    /// `GET /library/metadata/{id}/extras`.
    public func extras(ratingKey: String) async throws -> PlexMediaContainer {
        try await container(.extras(ratingKey: ratingKey))
    }

    /// Filter fields (genre, year, unwatched, …). Load a filter's values with `container(key: filter.key)`.
    public func filters(sectionID: String) async throws -> [PlexDirectory] {
        try await container(PlexEndpoint(.get, "/library/sections/\(try PlexURLBuilder.segment(sectionID))/filters")).directories
    }

    /// `GET /library/sections/{id}/sorts`.
    public func sorts(sectionID: String) async throws -> [PlexDirectory] {
        try await container(PlexEndpoint(.get, "/library/sections/\(try PlexURLBuilder.segment(sectionID))/sorts")).directories
    }

    /// The alphabet jump bar: one row per leading character with its item count.
    public func firstCharacters(
        sectionID: String, query: PlexLibraryQuery = PlexLibraryQuery()
    ) async throws -> [PlexDirectory] {
        let path = "/library/sections/\(try PlexURLBuilder.segment(sectionID))/firstCharacter"
        return try await container(PlexEndpoint(.get, path, query: query.items)).directories
    }

    /// Top-level folders; follow each directory's key with `container(key:)`.
    public func folders(sectionID: String) async throws -> PlexMediaContainer {
        let path = "/library/sections/\(try PlexURLBuilder.segment(sectionID))/folder"
        return try await container(PlexEndpoint(.get, path, query: [URLQueryItem(name: "includeCollections", value: "0")]))
    }

    /// Everything a cast or crew member (a `PlexTag.tagID`) appears in.
    public func personMedia(personID: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        let path = "/library/people/\(try PlexURLBuilder.segment(personID))/media"
        return try await container(PlexEndpoint(.get, path, query: page?.query ?? []))
    }

    /// `GET {key}`: follows any server-relative key, such as a filter's values or a hub's full list.
    public func container(key: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        try await container(PlexEndpoint(.get, key, query: page?.query ?? []))
    }

    /// Plans original-file downloads for an item.
    /// - Parameters:
    ///   - ratingKey: A movie, episode or clip.
    ///   - mediaIndex: The preferred version; an unavailable or invalid index falls back to the first downloadable version.
    ///   - selection: `.allParts` (default) or `.firstPlayable`, Plezy's one-part behavior.
    /// - Throws: `PlexAPIError.noDownloadableMedia` or `.unavailablePart` when files are missing.
    public func downloadPlan(
        ratingKey: String, mediaIndex: Int = 0, selection: PlexDownloadPartSelection = .allParts
    ) async throws -> PlexDownloadPlan {
        let item = try await metadata(ratingKey: ratingKey)
        return try PlexDownloadPlanner(configuration: configuration).plan(for: item, mediaIndex: mediaIndex, selection: selection)
    }
}

// MARK: - server:// URIs

extension PlexAPIService {
    /// The configured machine identifier, or the server's `/identity` when connected manually.
    public func machineIdentifier() async throws -> String {
        if let identifier = configuration.machineIdentifier { return identifier }
        guard let identifier = try await container(PlexEndpoint(.get, "/identity")).machineIdentifier
        else { throw PlexAPIError.missingMachineIdentifier }
        return identifier
    }

    /// `server://{machine}/com.plexapp.plugins.library{path}`, used by playlists, collections and play queues.
    public func libraryURI(path: String) async throws -> String {
        "server://\(try await machineIdentifier())/com.plexapp.plugins.library\(path)"
    }

    func metadataURI(_ ratingKeys: [String]) async throws -> String {
        let keys = try ratingKeys.map(PlexURLBuilder.segment).joined(separator: ",")
        return try await libraryURI(path: "/library/metadata/" + keys)
    }
}
