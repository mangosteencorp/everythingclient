import Foundation

/// A movie, show, season, episode, collection, playlist, clip or other library item.
/// Unknown `type` values are retained. Durations and offsets are milliseconds; IDs are scoped to one server.
/// `Codable` so apps can keep downloaded items browsable offline.
public struct PlexMetadata: Codable, Sendable, Equatable, Hashable, Identifiable {
    /// The item ID on its server; pass it to every item-scoped API.
    public let ratingKey: String
    /// The display title; for an episode, the episode's own title.
    public let title: String
    /// `movie`, `show`, `season`, `episode`, `collection`, `playlist`, `clip`, or another server type.
    public let type: String
    /// The server path for the item or, for containers, its children.
    public let key: String?
    /// A cross-server identifier such as `plex://movie/…`.
    public let guid: String?
    /// A refinement such as `trailer` for clips or `movie` for collections.
    public let subtype: String?
    /// The synopsis.
    public let summary: String?
    /// A one-line tagline.
    public let tagline: String?
    /// Release year.
    public let year: Int?
    /// Episode number, or season number for seasons.
    public let index: Int?
    /// Season number, for episodes.
    public let parentIndex: Int?
    /// Season title for episodes, or show title for seasons.
    public let parentTitle: String?
    /// Show title, for episodes.
    public let grandparentTitle: String?
    /// The season's (or show's) rating key.
    public let parentRatingKey: String?
    /// The show's rating key, for episodes.
    public let grandparentRatingKey: String?
    /// The library section that contains the item.
    public let librarySectionID: String?
    /// That section's title.
    public let librarySectionTitle: String?
    /// Age rating such as `PG-13`.
    public let contentRating: String?
    /// Studio or network.
    public let studio: String?
    /// Release or air date, `yyyy-MM-dd`.
    public let originallyAvailableAt: String?
    /// Critic rating, 0–10.
    public let rating: Double?
    /// Audience rating, 0–10.
    public let audienceRating: Double?
    /// This account's rating, 0–10; set it with `rate(ratingKey:rating:)`.
    public let userRating: Double?
    /// Running time in milliseconds.
    public let duration: Int64?
    /// Resume position in milliseconds.
    public let viewOffset: Int64?
    /// Times played to completion.
    public let viewCount: Int?
    /// Number of episodes (or items) under a container.
    public let leafCount: Int?
    /// Number of those already watched.
    public let viewedLeafCount: Int?
    /// Number of direct children, such as seasons or collection members.
    public let childCount: Int?
    /// When the item was added, in seconds since 1970.
    public let addedAt: Int64?
    /// When it was last watched, in seconds since 1970.
    public let lastViewedAt: Int64?
    /// Playlist entry identifier; required to remove or move a playlist item.
    public let playlistItemID: String?
    /// `video`, `audio` or `photo`, for playlists.
    public let playlistType: String?
    /// Whether a playlist or collection is rule-based and so cannot be edited by hand.
    public let smart: Bool?
    /// Poster path; load it with `imageRequest(path:width:height:)`.
    public let thumb: String?
    /// Background art path.
    public let art: String?
    /// Season poster, for episodes.
    public let parentThumb: String?
    /// Show poster, for episodes.
    public let grandparentThumb: String?
    /// Generated mosaic artwork, for playlists.
    public let composite: String?
    /// Available versions (files) of a playable item. Requested in full by `metadata(ratingKey:)`.
    public let media: [PlexMediaVersion]
    /// Genres.
    public let genres: [PlexTag]
    /// Directors.
    public let directors: [PlexTag]
    /// Writers.
    public let writers: [PlexTag]
    /// Cast, with each character in `role`.
    public let roles: [PlexTag]
    /// Intro and credits markers for skip buttons.
    public let markers: [PlexMarker]
    /// For shows and seasons fetched with `includeOnDeck=1`: the next episode to watch.
    public let onDeck: [PlexMetadata]
    /// The rating key.
    public var id: String { ratingKey }

    /// Leaves are watched once played; containers once every leaf is.
    public var isWatched: Bool {
        if let leafCount, leafCount > 0 { return (viewedLeafCount ?? 0) >= leafCount }
        return (viewCount ?? 0) > 0
    }

    /// Fraction played for resumable items, or nil when not in progress.
    public var progress: Double? {
        guard let viewOffset, let duration, duration > 0, viewOffset > 0 else { return nil }
        return min(Double(viewOffset) / Double(duration), 1)
    }

    /// The best poster for list rows: episodes fall back to their show's poster.
    public var posterPath: String? { type == "episode" ? grandparentThumb ?? parentThumb ?? thumb : thumb ?? composite }

    /// Creates an item, for example for previews, tests or an offline placeholder.
    public init(
        ratingKey: String, title: String, type: String, key: String? = nil, summary: String? = nil,
        year: Int? = nil, index: Int? = nil, parentIndex: Int? = nil, parentTitle: String? = nil,
        grandparentTitle: String? = nil, duration: Int64? = nil, viewOffset: Int64? = nil, viewCount: Int? = nil,
        parentRatingKey: String? = nil, grandparentRatingKey: String? = nil, librarySectionID: String? = nil,
        playlistItemID: String? = nil, thumb: String? = nil, art: String? = nil, media: [PlexMediaVersion] = []
    ) {
        self.ratingKey = ratingKey
        self.title = title
        self.type = type
        self.key = key
        self.summary = summary
        self.year = year
        self.index = index
        self.parentIndex = parentIndex
        self.parentTitle = parentTitle
        self.grandparentTitle = grandparentTitle
        self.duration = duration
        self.viewOffset = viewOffset
        self.viewCount = viewCount
        self.parentRatingKey = parentRatingKey
        self.grandparentRatingKey = grandparentRatingKey
        self.librarySectionID = librarySectionID
        self.playlistItemID = playlistItemID
        self.thumb = thumb
        self.art = art
        self.media = media
        guid = nil
        subtype = nil
        tagline = nil
        librarySectionTitle = nil
        contentRating = nil
        studio = nil
        originallyAvailableAt = nil
        rating = nil
        audienceRating = nil
        userRating = nil
        leafCount = nil
        viewedLeafCount = nil
        childCount = nil
        addedAt = nil
        lastViewedAt = nil
        playlistType = nil
        smart = nil
        parentThumb = nil
        grandparentThumb = nil
        composite = nil
        genres = []
        directors = []
        writers = []
        roles = []
        markers = []
        onDeck = []
    }

    enum CodingKeys: String, CodingKey {
        case ratingKey, title, type, key, guid, subtype, summary, tagline, year, index, parentIndex
        case parentTitle, grandparentTitle, parentRatingKey, grandparentRatingKey, librarySectionID
        case librarySectionTitle, contentRating, studio, originallyAvailableAt, rating, audienceRating
        case userRating, duration, viewOffset, viewCount, leafCount, viewedLeafCount, childCount, addedAt
        case lastViewedAt, playlistItemID, playlistType, smart, thumb, art, parentThumb, grandparentThumb, composite
        case media = "Media", genres = "Genre", directors = "Director", writers = "Writer", roles = "Role"
        case markers = "Marker", onDeck = "OnDeck"
    }

    /// Decodes Plex's mixed scalar types, single-object arrays and the nested `OnDeck` form.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ratingKey = try values.requiredString(forKey: .ratingKey)
        title = try values.flexibleString(forKey: .title) ?? ""
        type = try values.decode(String.self, forKey: .type)
        key = try values.decodeIfPresent(String.self, forKey: .key)
        guid = try values.decodeIfPresent(String.self, forKey: .guid)
        subtype = try values.decodeIfPresent(String.self, forKey: .subtype)
        summary = try values.decodeIfPresent(String.self, forKey: .summary)
        tagline = try values.decodeIfPresent(String.self, forKey: .tagline)
        year = try values.flexibleInteger(forKey: .year)
        index = try values.flexibleInteger(forKey: .index)
        parentIndex = try values.flexibleInteger(forKey: .parentIndex)
        parentTitle = try values.flexibleString(forKey: .parentTitle)
        grandparentTitle = try values.flexibleString(forKey: .grandparentTitle)
        parentRatingKey = try values.flexibleString(forKey: .parentRatingKey)
        grandparentRatingKey = try values.flexibleString(forKey: .grandparentRatingKey)
        librarySectionID = try values.flexibleString(forKey: .librarySectionID)
        librarySectionTitle = try values.decodeIfPresent(String.self, forKey: .librarySectionTitle)
        contentRating = try values.decodeIfPresent(String.self, forKey: .contentRating)
        studio = try values.decodeIfPresent(String.self, forKey: .studio)
        originallyAvailableAt = try values.decodeIfPresent(String.self, forKey: .originallyAvailableAt)
        rating = try values.flexibleDouble(forKey: .rating)
        audienceRating = try values.flexibleDouble(forKey: .audienceRating)
        userRating = try values.flexibleDouble(forKey: .userRating)
        duration = try values.flexibleInteger(forKey: .duration)
        viewOffset = try values.flexibleInteger(forKey: .viewOffset)
        viewCount = try values.flexibleInteger(forKey: .viewCount)
        leafCount = try values.flexibleInteger(forKey: .leafCount)
        viewedLeafCount = try values.flexibleInteger(forKey: .viewedLeafCount)
        childCount = try values.flexibleInteger(forKey: .childCount)
        addedAt = try values.flexibleInteger(forKey: .addedAt)
        lastViewedAt = try values.flexibleInteger(forKey: .lastViewedAt)
        playlistItemID = try values.flexibleString(forKey: .playlistItemID)
        playlistType = try values.decodeIfPresent(String.self, forKey: .playlistType)
        smart = try values.flexibleBool(forKey: .smart)
        thumb = try values.decodeIfPresent(String.self, forKey: .thumb)
        art = try values.decodeIfPresent(String.self, forKey: .art)
        parentThumb = try values.decodeIfPresent(String.self, forKey: .parentThumb)
        grandparentThumb = try values.decodeIfPresent(String.self, forKey: .grandparentThumb)
        composite = try values.decodeIfPresent(String.self, forKey: .composite)
        media = try values.flexibleArray(forKey: .media)
        genres = try values.lossyArray(forKey: .genres)
        directors = try values.lossyArray(forKey: .directors)
        writers = try values.lossyArray(forKey: .writers)
        roles = try values.lossyArray(forKey: .roles)
        markers = try values.lossyArray(forKey: .markers)
        // The server nests the next episode as OnDeck.Metadata; re-encoded values are a plain array.
        onDeck = try (try? values.decode(PlexOnDeck.self, forKey: .onDeck).metadata) ?? values.lossyArray(forKey: .onDeck)
    }
}

/// The server's `OnDeck` wrapper: `{"Metadata": {...}}`.
private struct PlexOnDeck: Decodable {
    let metadata: [PlexMetadata]

    init(from decoder: any Decoder) throws {
        metadata = try decoder.container(keyedBy: PlexCodingKey.self).lossyArray(forKey: PlexCodingKey("Metadata"))
    }
}
