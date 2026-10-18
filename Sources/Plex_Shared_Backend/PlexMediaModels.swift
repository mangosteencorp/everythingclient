import Foundation

/// One version of an item, such as a 4K and a 1080p file.
public struct PlexMediaVersion: Codable, Sendable, Hashable {
    /// The media ID.
    public let id: String?
    /// File container, such as `mkv` or `mp4`.
    public let container: String?
    /// Video codec, such as `h264` or `hevc`.
    public let videoCodec: String?
    /// Primary audio codec.
    public let audioCodec: String?
    /// Resolution label, such as `1080` or `4k`.
    public let videoResolution: String?
    /// Frame width in pixels.
    public let width: Int?
    /// Frame height in pixels.
    public let height: Int?
    /// Overall bitrate in kbps.
    public let bitrate: Int?
    /// Primary audio channel count.
    public let audioChannels: Int?
    /// Duration in milliseconds.
    public let duration: Int64?
    /// The files that make up this version, in playback order.
    public let parts: [PlexMediaPart]

    /// Creates a version, for example in tests.
    public init(
        id: String? = nil, container: String? = nil, videoCodec: String? = nil, audioCodec: String? = nil,
        videoResolution: String? = nil, width: Int? = nil, height: Int? = nil, bitrate: Int? = nil,
        audioChannels: Int? = nil, duration: Int64? = nil, parts: [PlexMediaPart] = []
    ) {
        self.id = id
        self.container = container
        self.videoCodec = videoCodec
        self.audioCodec = audioCodec
        self.videoResolution = videoResolution
        self.width = width
        self.height = height
        self.bitrate = bitrate
        self.audioChannels = audioChannels
        self.duration = duration
        self.parts = parts
    }

    enum CodingKeys: String, CodingKey {
        case id, container, videoCodec, audioCodec, videoResolution, width, height, bitrate, audioChannels, duration
        case parts = "Part"
    }

    /// Decodes a version and its parts.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.flexibleString(forKey: .id)
        container = try values.decodeIfPresent(String.self, forKey: .container)
        videoCodec = try values.decodeIfPresent(String.self, forKey: .videoCodec)
        audioCodec = try values.decodeIfPresent(String.self, forKey: .audioCodec)
        videoResolution = try values.flexibleString(forKey: .videoResolution)
        width = try values.flexibleInteger(forKey: .width)
        height = try values.flexibleInteger(forKey: .height)
        bitrate = try values.flexibleInteger(forKey: .bitrate)
        audioChannels = try values.flexibleInteger(forKey: .audioChannels)
        duration = try values.flexibleInteger(forKey: .duration)
        parts = try values.flexibleArray(forKey: .parts)
    }
}

/// One file of a media version. Split movies have several parts.
public struct PlexMediaPart: Codable, Sendable, Hashable {
    /// The part ID, used by stream selection and preview thumbnails.
    public let id: String?
    /// Server path of the original file; play or download it with `directPlayRequest(part:)`.
    public let key: String?
    /// The file's path on the server's disk.
    public let file: String?
    /// File container.
    public let container: String?
    /// File size in bytes.
    public let size: Int64?
    /// Duration in milliseconds.
    public let duration: Int64?
    /// Whether the file exists on disk (sent when `checkFiles=1`).
    public let exists: Bool?
    /// Whether the server can read the file (sent when `checkFiles=1`).
    public let accessible: Bool?
    /// Video, audio and subtitle streams in this file.
    public let streams: [PlexMediaStream]
    /// Missing accessibility fields are allowed; Plex supplies them when `checkFiles=1` is requested.
    public var isPlayable: Bool { exists != false && accessible != false }

    /// Creates a part, for example in tests.
    public init(
        id: String? = nil, key: String? = nil, file: String? = nil, container: String? = nil, size: Int64? = nil,
        duration: Int64? = nil, exists: Bool? = nil, accessible: Bool? = nil, streams: [PlexMediaStream] = []
    ) {
        self.id = id
        self.key = key
        self.file = file
        self.container = container
        self.size = size
        self.duration = duration
        self.exists = exists
        self.accessible = accessible
        self.streams = streams
    }

    enum CodingKeys: String, CodingKey {
        case id, key, file, container, size, duration, exists, accessible
        case streams = "Stream"
    }

    /// Decodes a part; malformed availability flags fail rather than become playable.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.flexibleString(forKey: .id)
        key = try values.decodeIfPresent(String.self, forKey: .key)
        file = try values.decodeIfPresent(String.self, forKey: .file)
        container = try values.decodeIfPresent(String.self, forKey: .container)
        size = try values.flexibleInteger(forKey: .size)
        duration = try values.flexibleInteger(forKey: .duration)
        exists = try values.flexibleBool(forKey: .exists)
        accessible = try values.flexibleBool(forKey: .accessible)
        streams = try values.flexibleArray(forKey: .streams)
    }
}

/// A video, audio or subtitle stream inside a media part.
public struct PlexMediaStream: Codable, Sendable, Hashable, Identifiable {
    /// The stream ID, used by `selectStreams(partID:audioStreamID:subtitleStreamID:)`.
    public let streamID: String?
    /// Plex uses 1 for video, 2 for audio, and 3 for subtitle streams.
    public let streamType: Int
    /// Server path of an external subtitle file; nil for embedded streams.
    public let key: String?
    /// Codec, such as `aac` or `srt`.
    public let codec: String?
    /// Language name.
    public let language: String?
    /// ISO 639-2 language code.
    public let languageCode: String?
    /// Human-readable description, such as `English (AAC Stereo)`.
    public let displayTitle: String?
    /// Whether the subtitle is forced (foreign dialogue only).
    public let forced: Bool?
    /// Whether the server selects this stream by default.
    public let selected: Bool?
    /// The stream ID, or a fallback for streams without one.
    public var id: String { streamID ?? key ?? "\(streamType)-\(displayTitle ?? "")" }
    /// Whether this is a separate subtitle file that can be downloaded as a sidecar.
    public var isExternalSubtitle: Bool { streamType == 3 && key?.isEmpty == false }

    /// Creates a stream, for example in tests.
    public init(
        id: String? = nil, streamType: Int, key: String? = nil, codec: String? = nil,
        language: String? = nil, languageCode: String? = nil, displayTitle: String? = nil,
        forced: Bool? = nil, selected: Bool? = nil
    ) {
        streamID = id
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
        case streamType, key, codec, language, languageCode, displayTitle, forced, selected
        case streamID = "id"
    }

    /// Decodes a stream; `streamType` is required.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        streamID = try values.flexibleString(forKey: .streamID)
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
