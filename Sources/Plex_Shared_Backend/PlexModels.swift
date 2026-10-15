import Foundation

/// The top-level JSON object of a Plex Media Server response.
public struct PlexResponse: Decodable, Sendable, Equatable {
    /// The `MediaContainer` envelope.
    public let mediaContainer: PlexMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

/// The envelope of nearly every Plex Media Server response.
/// `Metadata`, `Directory` and `Hub` lists skip individual elements that fail to decode.
public struct PlexMediaContainer: Decodable, Sendable, Equatable {
    /// Number of entries in this response.
    public let size: Int?
    /// Total entries available across all pages, when the endpoint pages.
    public let totalSize: Int?
    /// Index of the first entry in this page.
    public let offset: Int?
    /// The container title (`title1`), such as a library name.
    public let title: String?
    /// The server's machine identifier, on `/` and `/identity`.
    public let machineIdentifier: String?
    /// The library section the entries belong to, when uniform.
    public let librarySectionID: String?
    /// That section's title.
    public let librarySectionTitle: String?
    /// `Directory` rows: sections, filters, sorts, filter values, first characters or folders.
    public let directories: [PlexDirectory]
    /// `Metadata` items, plus search hits unwrapped from `SearchResult`.
    public let metadata: [PlexMetadata]
    /// `Hub` shelves from the hubs endpoints.
    public let hubs: [PlexHub]
    /// Library sections are the `Directory` entries that carry a type.
    public var libraries: [PlexLibrary] {
        directories.compactMap { directory in
            directory.type.map { PlexLibrary(key: directory.key, title: directory.title, type: $0, uuid: directory.uuid) }
        }
    }

    enum CodingKeys: String, CodingKey {
        case size, totalSize, offset, machineIdentifier, librarySectionID, librarySectionTitle
        case title = "title1"
        case directories = "Directory", metadata = "Metadata", hubs = "Hub", searchResults = "SearchResult"
    }

    /// Decodes Plex's mixed number/string fields and skips individual entries that fail to decode.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        size = try values.flexibleInteger(forKey: .size)
        totalSize = try values.flexibleInteger(forKey: .totalSize)
        offset = try values.flexibleInteger(forKey: .offset)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        machineIdentifier = try values.flexibleString(forKey: .machineIdentifier)
        librarySectionID = try values.flexibleString(forKey: .librarySectionID)
        librarySectionTitle = try values.decodeIfPresent(String.self, forKey: .librarySectionTitle)
        directories = try values.lossyArray(forKey: .directories)
        hubs = try values.lossyArray(forKey: .hubs)
        // /library/search wraps each hit as SearchResult[].Metadata.
        let searchResults: [PlexSearchResult] = try values.lossyArray(forKey: .searchResults)
        metadata = try values.lossyArray(forKey: .metadata) + searchResults.map(\.metadata)
    }
}

private struct PlexSearchResult: Decodable {
    let metadata: PlexMetadata
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}

/// A library section such as Movies or TV Shows.
public struct PlexLibrary: Codable, Sendable, Equatable, Hashable, Identifiable {
    /// The section ID used by section endpoints.
    public let key: String
    /// The section name.
    public let title: String
    /// movie, show, artist or photo.
    public let type: String
    /// A stable identifier that survives section renames.
    public let uuid: String?
    /// The section key.
    public var id: String { key }

    /// Creates a section, for example for previews or tests.
    public init(key: String, title: String, type: String, uuid: String? = nil) {
        self.key = key
        self.title = title
        self.type = type
        self.uuid = uuid
    }
}

/// A `Directory` row: library sections, filters, sorts, filter values, first characters and folders
/// all share this shape and differ only in which optional fields are present.
public struct PlexDirectory: Codable, Sendable, Hashable, Identifiable {
    /// The directory key: a section ID, a sort key, a filter value, or a server path to follow.
    public let key: String
    /// The display title.
    public let title: String
    /// The section type for libraries, or `filter` for filters.
    public let type: String?
    /// A section's stable identifier.
    public let uuid: String?
    /// Artwork path, if any.
    public let thumb: String?
    /// Filters: the query parameter name (for example `genre`) and its value type.
    public let filter: String?
    /// `string`, `integer` or `boolean` for filters.
    public let filterType: String?
    /// Sorts: the descending sort value and the server's default direction.
    public let descKey: String?
    /// `asc` or `desc` for sorts.
    public let defaultDirection: String?
    /// First characters: the number of items starting with `title`.
    public let size: Int?
    /// The directory key.
    public var id: String { key }

    enum CodingKeys: String, CodingKey { case key, title, type, uuid, thumb, filter, filterType, descKey, defaultDirection, size }

    /// Decodes a directory row; a missing title falls back to the key.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.requiredString(forKey: .key)
        title = try values.flexibleString(forKey: .title) ?? key
        type = try values.decodeIfPresent(String.self, forKey: .type)
        uuid = try values.decodeIfPresent(String.self, forKey: .uuid)
        thumb = try values.decodeIfPresent(String.self, forKey: .thumb)
        filter = try values.decodeIfPresent(String.self, forKey: .filter)
        filterType = try values.decodeIfPresent(String.self, forKey: .filterType)
        descKey = try values.decodeIfPresent(String.self, forKey: .descKey)
        defaultDirection = try values.decodeIfPresent(String.self, forKey: .defaultDirection)
        size = try values.flexibleInteger(forKey: .size)
    }
}

/// A home, library or related shelf. `key` lists the full contents; `more` says the preview is partial.
public struct PlexHub: Decodable, Sendable, Hashable, Identifiable {
    /// A stable shelf identifier such as `home.continue` or `movie.recentlyadded.1`.
    public let hubIdentifier: String
    /// Server path listing the shelf's full contents; follow it with `container(key:page:)`.
    public let key: String?
    /// The shelf title.
    public let title: String
    /// The item type shown on the shelf, such as `movie` or `mixed`.
    public let type: String?
    /// Number of items in the preview.
    public let size: Int?
    /// Whether more items exist beyond the preview.
    public let more: Bool
    /// The preview items.
    public let metadata: [PlexMetadata]
    /// The hub identifier.
    public var id: String { hubIdentifier }

    enum CodingKeys: String, CodingKey {
        case hubIdentifier, key, title, type, size, more
        case metadata = "Metadata"
    }

    /// Decodes a hub; without an identifier it falls back to its key or title.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        key = try values.decodeIfPresent(String.self, forKey: .key)
        hubIdentifier = try values.decodeIfPresent(String.self, forKey: .hubIdentifier) ?? key ?? title
        type = try values.decodeIfPresent(String.self, forKey: .type)
        size = try values.flexibleInteger(forKey: .size)
        more = try values.flexibleBool(forKey: .more) ?? false
        metadata = try values.lossyArray(forKey: .metadata)
    }
}

/// Genre, director, writer and cast entries. `role` is the character name for cast members.
public struct PlexTag: Codable, Sendable, Hashable, Identifiable {
    /// The person's name or genre name.
    public let tag: String
    /// The tag ID; for people, pass it to `personMedia(personID:page:)`.
    public let tagID: String?
    /// The character played, for cast members.
    public let role: String?
    /// A headshot or artwork URL.
    public let thumb: String?
    /// The tag ID, or the name when the server sends none.
    public var id: String { tagID ?? tag }

    enum CodingKeys: String, CodingKey {
        case tag, role, thumb
        case tagID = "id"
    }

    /// Decodes a tag; numeric IDs become strings.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tag = try values.decode(String.self, forKey: .tag)
        tagID = try values.flexibleString(forKey: .tagID)
        role = try values.decodeIfPresent(String.self, forKey: .role)
        thumb = try values.decodeIfPresent(String.self, forKey: .thumb)
    }
}

/// Intro and credits markers, returned when metadata is requested with `includeMarkers=1`.
public struct PlexMarker: Codable, Sendable, Hashable {
    /// `intro` or `credits`.
    public let type: String
    /// Start position in milliseconds.
    public let startTimeOffset: Int64
    /// End position in milliseconds; skipping seeks here.
    public let endTimeOffset: Int64

    /// Creates a marker, for example in tests.
    public init(type: String, startTimeOffset: Int64, endTimeOffset: Int64) {
        self.type = type
        self.startTimeOffset = startTimeOffset
        self.endTimeOffset = endTimeOffset
    }

    enum CodingKeys: String, CodingKey { case type, startTimeOffset, endTimeOffset }

    /// Decodes a marker; missing offsets become zero.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        startTimeOffset = try values.flexibleInteger(forKey: .startTimeOffset) ?? 0
        endTimeOffset = try values.flexibleInteger(forKey: .endTimeOffset) ?? 0
    }
}
