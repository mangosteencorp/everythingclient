import Foundation

public struct PlexResponse: Decodable, Sendable, Equatable {
    public let mediaContainer: PlexMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

public struct PlexMediaContainer: Decodable, Sendable, Equatable {
    public let size: Int?
    public let totalSize: Int?
    public let offset: Int?
    public let libraries: [PlexLibrary]
    public let metadata: [PlexMetadata]

    enum CodingKeys: String, CodingKey {
        case size, totalSize, offset
        case libraries = "Directory", metadata = "Metadata"
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        size = try values.flexibleInteger(forKey: .size)
        totalSize = try values.flexibleInteger(forKey: .totalSize)
        offset = try values.flexibleInteger(forKey: .offset)
        libraries = try values.flexibleArray(forKey: .libraries)
        metadata = try values.flexibleArray(forKey: .metadata)
    }
}

public struct PlexLibrary: Decodable, Sendable, Equatable, Identifiable {
    public let key: String
    public let title: String
    public let type: String
    public let uuid: String?
    public var id: String { key }

    public init(key: String, title: String, type: String, uuid: String? = nil) {
        self.key = key
        self.title = title
        self.type = type
        self.uuid = uuid
    }

    enum CodingKeys: String, CodingKey { case key, title, type, uuid }
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.requiredString(forKey: .key)
        title = try values.decode(String.self, forKey: .title)
        type = try values.decode(String.self, forKey: .type)
        uuid = try values.decodeIfPresent(String.self, forKey: .uuid)
    }
}

/// A movie, show, season, episode, or other metadata item. Unknown `type` values are retained.
/// Plex reports duration and viewOffset in milliseconds; IDs are scoped to one server.
public struct PlexMetadata: Decodable, Sendable, Equatable, Identifiable {
    public let ratingKey: String
    public let title: String
    public let type: String
    public let key: String?
    public let summary: String?
    public let year: Int?
    public let duration: Int64?
    public let viewOffset: Int64?
    public let parentRatingKey: String?
    public let grandparentRatingKey: String?
    public let thumb: String?
    public let art: String?
    public let media: [PlexMediaVersion]
    public var id: String { ratingKey }

    public init(
        ratingKey: String, title: String, type: String, key: String? = nil, summary: String? = nil,
        year: Int? = nil, duration: Int64? = nil, viewOffset: Int64? = nil,
        parentRatingKey: String? = nil, grandparentRatingKey: String? = nil,
        thumb: String? = nil, art: String? = nil, media: [PlexMediaVersion] = []
    ) {
        self.ratingKey = ratingKey
        self.title = title
        self.type = type
        self.key = key
        self.summary = summary
        self.year = year
        self.duration = duration
        self.viewOffset = viewOffset
        self.parentRatingKey = parentRatingKey
        self.grandparentRatingKey = grandparentRatingKey
        self.thumb = thumb
        self.art = art
        self.media = media
    }

    enum CodingKeys: String, CodingKey {
        case ratingKey, title, type, key, summary, year, duration, viewOffset
        case parentRatingKey, grandparentRatingKey, thumb, art
        case media = "Media"
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ratingKey = try values.requiredString(forKey: .ratingKey)
        title = try values.decode(String.self, forKey: .title)
        type = try values.decode(String.self, forKey: .type)
        key = try values.decodeIfPresent(String.self, forKey: .key)
        summary = try values.decodeIfPresent(String.self, forKey: .summary)
        year = try values.flexibleInteger(forKey: .year)
        duration = try values.flexibleInteger(forKey: .duration)
        viewOffset = try values.flexibleInteger(forKey: .viewOffset)
        parentRatingKey = try values.flexibleString(forKey: .parentRatingKey)
        grandparentRatingKey = try values.flexibleString(forKey: .grandparentRatingKey)
        thumb = try values.decodeIfPresent(String.self, forKey: .thumb)
        art = try values.decodeIfPresent(String.self, forKey: .art)
        media = try values.flexibleArray(forKey: .media)
    }
}

public struct PlexMediaVersion: Decodable, Sendable, Equatable {
    public let id: String?
    public let container: String?
    public let videoCodec: String?
    public let audioCodec: String?
    public let videoResolution: String?
    public let width: Int?
    public let height: Int?
    public let parts: [PlexMediaPart]

    public init(
        id: String? = nil, container: String? = nil, videoCodec: String? = nil, audioCodec: String? = nil,
        videoResolution: String? = nil, width: Int? = nil, height: Int? = nil, parts: [PlexMediaPart] = []
    ) {
        self.id = id
        self.container = container
        self.videoCodec = videoCodec
        self.audioCodec = audioCodec
        self.videoResolution = videoResolution
        self.width = width
        self.height = height
        self.parts = parts
    }

    enum CodingKeys: String, CodingKey {
        case id, container, videoCodec, audioCodec, videoResolution, width, height
        case parts = "Part"
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.flexibleString(forKey: .id)
        container = try values.decodeIfPresent(String.self, forKey: .container)
        videoCodec = try values.decodeIfPresent(String.self, forKey: .videoCodec)
        audioCodec = try values.decodeIfPresent(String.self, forKey: .audioCodec)
        videoResolution = try values.flexibleString(forKey: .videoResolution)
        width = try values.flexibleInteger(forKey: .width)
        height = try values.flexibleInteger(forKey: .height)
        parts = try values.flexibleArray(forKey: .parts)
    }
}

public struct PlexMediaPart: Decodable, Sendable, Equatable {
    public let id: String?
    public let key: String?
    public let container: String?
    public let size: Int64?
    public let exists: Bool?
    public let accessible: Bool?
    public let streams: [PlexMediaStream]
    /// Missing accessibility fields are allowed; Plex supplies them when `checkFiles=1` is requested.
    public var isPlayable: Bool { exists != false && accessible != false }

    public init(
        id: String? = nil, key: String? = nil, container: String? = nil, size: Int64? = nil,
        exists: Bool? = nil, accessible: Bool? = nil, streams: [PlexMediaStream] = []
    ) {
        self.id = id
        self.key = key
        self.container = container
        self.size = size
        self.exists = exists
        self.accessible = accessible
        self.streams = streams
    }

    enum CodingKeys: String, CodingKey {
        case id, key, container, size, exists, accessible
        case streams = "Stream"
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.flexibleString(forKey: .id)
        key = try values.decodeIfPresent(String.self, forKey: .key)
        container = try values.decodeIfPresent(String.self, forKey: .container)
        size = try values.flexibleInteger(forKey: .size)
        exists = try values.flexibleBool(forKey: .exists)
        accessible = try values.flexibleBool(forKey: .accessible)
        streams = try values.flexibleArray(forKey: .streams)
    }
}

public struct PlexMediaStream: Decodable, Sendable, Equatable {
    public let id: String?
    /// Plex uses 1 for video, 2 for audio, and 3 for subtitle streams.
    public let streamType: Int
    public let key: String?
    public let codec: String?
    public let language: String?
    public let languageCode: String?
    public let displayTitle: String?
    public let forced: Bool?
    public let selected: Bool?
    public var isExternalSubtitle: Bool { streamType == 3 && key?.isEmpty == false }

    public init(
        id: String? = nil, streamType: Int, key: String? = nil, codec: String? = nil,
        language: String? = nil, languageCode: String? = nil, displayTitle: String? = nil,
        forced: Bool? = nil, selected: Bool? = nil
    ) {
        self.id = id
        self.streamType = streamType
        self.key = key
        self.codec = codec
        self.language = language
        self.languageCode = languageCode
        self.displayTitle = displayTitle
        self.forced = forced
        self.selected = selected
    }

    enum CodingKeys: String, CodingKey {
        case id, streamType, key, codec, language, languageCode, displayTitle, forced, selected
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.flexibleString(forKey: .id)
        guard let type: Int = try values.flexibleInteger(forKey: .streamType) else {
            throw DecodingError.keyNotFound(CodingKeys.streamType, .init(codingPath: decoder.codingPath, debugDescription: "streamType"))
        }
        streamType = type
        key = try values.decodeIfPresent(String.self, forKey: .key)
        codec = try values.decodeIfPresent(String.self, forKey: .codec)
        language = try values.decodeIfPresent(String.self, forKey: .language)
        languageCode = try values.decodeIfPresent(String.self, forKey: .languageCode)
        displayTitle = try values.decodeIfPresent(String.self, forKey: .displayTitle)
        forced = try values.flexibleBool(forKey: .forced)
        selected = try values.flexibleBool(forKey: .selected)
    }
}

extension KeyedDecodingContainer {
    func flexibleString(forKey key: Key) throws -> String? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        if let string = try? decode(String.self, forKey: key) { return string }
        return String(try decode(Int64.self, forKey: key))
    }

    func requiredString(forKey key: Key) throws -> String {
        guard let value = try flexibleString(forKey: key) else {
            throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: key.stringValue))
        }
        return value
    }

    func flexibleInteger<Value: FixedWidthInteger & Decodable>(forKey key: Key) throws -> Value? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        if let value = try? decode(Value.self, forKey: key) { return value }
        let string = try decode(String.self, forKey: key)
        guard let value = Value(string) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: key.stringValue)
        }
        return value
    }

    func flexibleBool(forKey key: Key) throws -> Bool? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        if let value = try? decode(Bool.self, forKey: key) { return value }
        if let value = try? decode(Int.self, forKey: key), value == 0 || value == 1 { return value == 1 }
        let value = try decode(String.self, forKey: key).lowercased()
        switch value {
        case "1", "true": return true
        case "0", "false": return false
        default: throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: key.stringValue)
        }
    }

    func flexibleArray<Value: Decodable>(forKey key: Key) throws -> [Value] {
        guard contains(key), try !decodeNil(forKey: key) else { return [] }
        // A single Part/Media/Stream object is a valid Plex representation.
        if let array = try? decode([Value].self, forKey: key) { return array }
        return [try decode(Value.self, forKey: key)]
    }
}
