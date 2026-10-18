import Foundation

/// Library collections. Creating and editing requires a server owner or admin.
public protocol PlexCollectionServing: Sendable {
    /// A section's collections.
    func collections(sectionID: String, page: PlexPagination?) async throws -> PlexMediaContainer
    /// The members of a collection.
    func collectionItems(collectionID: String, page: PlexPagination?) async throws -> PlexMediaContainer
    /// Creates a collection in a section, optionally with initial members; returns it when the server echoes it.
    func createCollection(sectionID: String, title: String, type: Int?, ratingKeys: [String]) async throws -> PlexMetadata?
    /// Adds items to a collection.
    func addToCollection(collectionID: String, ratingKeys: [String]) async throws
    /// Removes one item from a collection.
    func removeFromCollection(collectionID: String, ratingKey: String) async throws
    /// Deletes a collection; its items stay in the library.
    func deleteCollection(collectionID: String) async throws
}

/// User playlists. Items carry a `playlistItemID` used to remove and reorder them.
public protocol PlexPlaylistServing: Sendable {
    /// This account's playlists of one type.
    func playlists(type: String, page: PlexPagination?) async throws -> PlexMediaContainer
    /// A playlist's details, such as title, item count and duration.
    func playlist(id: String) async throws -> PlexMetadata
    /// A playlist's entries, each with a `playlistItemID`.
    func playlistItems(id: String, page: PlexPagination?) async throws -> PlexMediaContainer
    /// Creates a video playlist, optionally with initial items; returns it when the server echoes it.
    func createPlaylist(title: String, ratingKeys: [String]) async throws -> PlexMetadata?
    /// Appends items to a playlist.
    func addToPlaylist(id: String, ratingKeys: [String]) async throws
    /// Removes one entry by its `playlistItemID`.
    func removeFromPlaylist(id: String, playlistItemID: String) async throws
    /// Moves an entry after another entry, or to the top when `afterPlaylistItemID` is nil.
    func movePlaylistItem(id: String, playlistItemID: String, afterPlaylistItemID: String?) async throws
    /// Deletes a playlist; its items stay in the library.
    func deletePlaylist(id: String) async throws
}

/// What a play queue is built from.
public enum PlexPlayQueueSource: Sendable, Equatable {
    /// Specific items, in order.
    case items([String])
    /// A library path such as a show's `/library/metadata/{id}/children` or a collection's children.
    case path(String)
    /// A playlist, by its rating key, in playlist order.
    case playlist(String)
}

/// Server-side play queues power "play all", shuffle and continuous episode playback.
public protocol PlexPlayQueueServing: Sendable {
    /// Creates a server-side play queue.
    /// - Parameters:
    ///   - source: The items, library path or playlist to queue.
    ///   - shuffle: Whether the server shuffles the queue.
    ///   - startingRatingKey: The item to start from; unshuffled queues then continue from it.
    func createPlayQueue(source: PlexPlayQueueSource, shuffle: Bool, startingRatingKey: String?) async throws -> PlexPlayQueue
    /// Re-reads a play queue, returning up to `window` items around the selected one.
    func playQueue(id: String, window: Int) async throws -> PlexPlayQueue
}

/// A server-side play queue: an ordered list of items with a current selection.
public struct PlexPlayQueue: Decodable, Sendable, Equatable {
    /// The queue ID (`playQueueID`).
    public let id: String
    /// Incremented by the server whenever the queue changes.
    public let version: Int?
    /// The queue entry currently selected.
    public let selectedItemID: String?
    /// Total entries, which can exceed `items` when windowed.
    public let totalCount: Int?
    /// Whether the queue is shuffled.
    public let shuffled: Bool
    /// The queued items, in play order.
    public let items: [PlexMetadata]

    enum Envelope: String, CodingKey { case mediaContainer = "MediaContainer" }
    enum CodingKeys: String, CodingKey {
        case id = "playQueueID", version = "playQueueVersion", selectedItemID = "playQueueSelectedItemID"
        case totalCount = "playQueueTotalCount", shuffled = "playQueueShuffled", items = "Metadata"
    }

    /// Decodes `MediaContainer.playQueue*` fields and `Metadata`.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: Envelope.self).nestedContainer(keyedBy: CodingKeys.self, forKey: .mediaContainer)
        id = try values.requiredString(forKey: .id)
        version = try values.flexibleInteger(forKey: .version)
        selectedItemID = try values.flexibleString(forKey: .selectedItemID)
        totalCount = try values.flexibleInteger(forKey: .totalCount)
        shuffled = try values.flexibleBool(forKey: .shuffled) ?? false
        items = try values.lossyArray(forKey: .items)
    }
}

extension PlexAPIService: PlexCollectionServing {
    /// `GET /library/sections/{id}/collections`.
    public func collections(sectionID: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        let path = "/library/sections/\(try PlexURLBuilder.segment(sectionID))/collections"
        return try await container(PlexEndpoint(.get, path, query: page?.query ?? []))
    }

    /// `GET /library/collections/{id}/children`.
    public func collectionItems(collectionID: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        try await container(PlexEndpoint(.get, try collectionPath(collectionID) + "/children", query: page?.query ?? []))
    }

    /// `type` is the Plex metadata type of the members: 1 movie, 2 show, 3 season, 4 episode.
    public func createCollection(
        sectionID: String, title: String, type: Int? = nil, ratingKeys: [String] = []
    ) async throws -> PlexMetadata? {
        let uri = ratingKeys.isEmpty ? "" : try await metadataURI(ratingKeys)
        let query = [type.map { URLQueryItem(name: "type", value: String($0)) }].compactMap { $0 } + [
            URLQueryItem(name: "title", value: title), URLQueryItem(name: "smart", value: "0"),
            URLQueryItem(name: "sectionId", value: sectionID), URLQueryItem(name: "uri", value: uri),
        ]
        return try await container(PlexEndpoint(.post, "/library/collections", query: query)).metadata.first
    }

    /// `PUT /library/collections/{id}/items?uri=server://…`; does nothing for an empty list.
    public func addToCollection(collectionID: String, ratingKeys: [String]) async throws {
        guard !ratingKeys.isEmpty else { return }
        let uri = try await metadataURI(ratingKeys)
        try await send(PlexEndpoint(.put, try collectionPath(collectionID) + "/items", query: [URLQueryItem(name: "uri", value: uri)]))
    }

    /// `DELETE /library/collections/{id}/items/{ratingKey}`.
    public func removeFromCollection(collectionID: String, ratingKey: String) async throws {
        try await send(PlexEndpoint(.delete, try collectionPath(collectionID) + "/items/\(try PlexURLBuilder.segment(ratingKey))"))
    }

    /// `DELETE /library/collections/{id}`.
    public func deleteCollection(collectionID: String) async throws {
        try await send(PlexEndpoint(.delete, try collectionPath(collectionID)))
    }

    private func collectionPath(_ id: String) throws -> String { "/library/collections/\(try PlexURLBuilder.segment(id))" }
}

extension PlexAPIService: PlexPlaylistServing {
    /// `type` is `video`, `audio` or `photo`.
    public func playlists(type: String = "video", page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        try await container(PlexEndpoint(.get, "/playlists", query: [URLQueryItem(name: "playlistType", value: type)] + (page?.query ?? [])))
    }

    /// `GET /playlists/{id}`.
    /// - Throws: `PlexAPIError.metadataNotFound` when the playlist is missing from the response.
    public func playlist(id: String) async throws -> PlexMetadata {
        guard let playlist = try await container(PlexEndpoint(.get, try playlistPath(id))).metadata.first
        else { throw PlexAPIError.metadataNotFound }
        return playlist
    }

    /// `GET /playlists/{id}/items`.
    public func playlistItems(id: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        try await container(PlexEndpoint(.get, try playlistPath(id) + "/items", query: page?.query ?? []))
    }

    /// `POST /playlists?type=video&title=…&smart=0`, with `uri=server://…` when items are given.
    public func createPlaylist(title: String, ratingKeys: [String] = []) async throws -> PlexMetadata? {
        var query = [
            URLQueryItem(name: "type", value: "video"), URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "smart", value: "0"),
        ]
        if !ratingKeys.isEmpty { query.append(URLQueryItem(name: "uri", value: try await metadataURI(ratingKeys))) }
        return try await container(PlexEndpoint(.post, "/playlists", query: query)).metadata.first
    }

    /// `PUT /playlists/{id}/items?uri=server://…`; does nothing for an empty list.
    public func addToPlaylist(id: String, ratingKeys: [String]) async throws {
        guard !ratingKeys.isEmpty else { return }
        let uri = try await metadataURI(ratingKeys)
        try await send(PlexEndpoint(.put, try playlistPath(id) + "/items", query: [URLQueryItem(name: "uri", value: uri)]))
    }

    /// `DELETE /playlists/{id}/items/{playlistItemID}`.
    public func removeFromPlaylist(id: String, playlistItemID: String) async throws {
        try await send(PlexEndpoint(.delete, try playlistPath(id) + "/items/\(try PlexURLBuilder.segment(playlistItemID))"))
    }

    /// Moves an entry after another entry, or to the top when `afterPlaylistItemID` is nil.
    public func movePlaylistItem(id: String, playlistItemID: String, afterPlaylistItemID: String?) async throws {
        let path = try playlistPath(id) + "/items/\(try PlexURLBuilder.segment(playlistItemID))/move"
        try await send(PlexEndpoint(.put, path, query: afterPlaylistItemID.map { [URLQueryItem(name: "after", value: $0)] } ?? []))
    }

    /// `DELETE /playlists/{id}`.
    public func deletePlaylist(id: String) async throws {
        try await send(PlexEndpoint(.delete, try playlistPath(id)))
    }

    private func playlistPath(_ id: String) throws -> String { "/playlists/\(try PlexURLBuilder.segment(id))" }
}

extension PlexAPIService: PlexPlayQueueServing {
    /// `POST /playQueues?type=video` with a `server://` `uri` or a `playlistID`, plus `shuffle`, `continuous` and starting `key`.
    public func createPlayQueue(
        source: PlexPlayQueueSource, shuffle: Bool = false, startingRatingKey: String? = nil
    ) async throws -> PlexPlayQueue {
        var query = [
            URLQueryItem(name: "type", value: "video"), URLQueryItem(name: "shuffle", value: shuffle ? "1" : "0"),
            URLQueryItem(name: "repeat", value: "0"),
            URLQueryItem(name: "continuous", value: startingRatingKey != nil && !shuffle ? "1" : "0"),
        ]
        switch source {
        case let .items(keys): query.append(URLQueryItem(name: "uri", value: try await metadataURI(keys)))
        case let .path(path): query.append(URLQueryItem(name: "uri", value: try await libraryURI(path: path)))
        case let .playlist(id): query.append(URLQueryItem(name: "playlistID", value: id))
        }
        if let startingRatingKey {
            query.append(URLQueryItem(name: "key", value: "/library/metadata/\(try PlexURLBuilder.segment(startingRatingKey))"))
        }
        return try await request(PlexEndpoint(.post, "/playQueues", query: query))
    }

    /// A window of items around the selected entry.
    public func playQueue(id: String, window: Int = 50) async throws -> PlexPlayQueue {
        try await request(PlexEndpoint(.get, "/playQueues/\(try PlexURLBuilder.segment(id))", query: [
            URLQueryItem(name: "window", value: String(window)),
            URLQueryItem(name: "includeBefore", value: "1"), URLQueryItem(name: "includeAfter", value: "1"),
        ]))
    }
}
