import Foundation

/// Options for an HLS transcode session, the format AVPlayer can stream.
public struct PlexStreamOptions: Sendable, Equatable {
    /// The movie, episode or clip to stream.
    public var ratingKey: String
    /// Which media version to stream.
    public var mediaIndex: Int
    /// Which part of that version to stream.
    public var partIndex: Int
    /// Reuse the same value for every request in one playback and to stop it afterwards.
    public var session: String
    /// Start position in milliseconds; sent to the server in whole seconds.
    public var offset: Int64?
    /// Nil keeps the original quality where the client profile allows it.
    public var maxVideoBitrateKbps: Int?
    /// Audio stream to use instead of the server default.
    public var audioStreamID: String?
    /// Subtitle stream to burn in; nil streams without subtitles.
    public var subtitleStreamID: String?

    /// Creates stream options; by default a new session at original quality with server-selected tracks.
    public init(
        ratingKey: String, mediaIndex: Int = 0, partIndex: Int = 0, session: String = UUID().uuidString,
        offset: Int64? = nil, maxVideoBitrateKbps: Int? = nil, audioStreamID: String? = nil, subtitleStreamID: String? = nil
    ) {
        self.ratingKey = ratingKey
        self.mediaIndex = mediaIndex
        self.partIndex = partIndex
        self.session = session
        self.offset = offset
        self.maxVideoBitrateKbps = maxVideoBitrateKbps
        self.audioStreamID = audioStreamID
        self.subtitleStreamID = subtitleStreamID
    }
}

/// A subtitle Plex can fetch from an online provider (OpenSubtitles and others) on the client's behalf.
public struct PlexSubtitleSearchResult: Decodable, Sendable, Equatable, Identifiable {
    /// Provider key to pass back to `downloadSubtitle(ratingKey:result:)`.
    public let key: String
    /// Subtitle format, such as `srt`.
    public let codec: String?
    /// Language code.
    public let language: String?
    /// Human-readable description.
    public let displayTitle: String?
    /// The provider that offers it, such as OpenSubtitles.
    public let providerTitle: String?
    /// The provider's match score.
    public let score: Double?
    /// Whether it includes sound descriptions for hearing-impaired viewers.
    public let hearingImpaired: Bool
    /// Whether it only covers foreign-language dialogue.
    public let forced: Bool
    /// The provider key.
    public var id: String { key }

    enum CodingKeys: String, CodingKey { case key, codec, language, languageCode, displayTitle, providerTitle, score, hearingImpaired, forced }

    /// Decodes a result, preferring `languageCode` over `language`.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.requiredString(forKey: .key)
        codec = try values.decodeIfPresent(String.self, forKey: .codec)
        language = try values.decodeIfPresent(String.self, forKey: .languageCode) ?? values.decodeIfPresent(String.self, forKey: .language)
        displayTitle = try values.decodeIfPresent(String.self, forKey: .displayTitle)
        providerTitle = try values.decodeIfPresent(String.self, forKey: .providerTitle)
        score = try values.flexibleDouble(forKey: .score)
        hearingImpaired = try values.flexibleBool(forKey: .hearingImpaired) ?? false
        forced = try values.flexibleBool(forKey: .forced) ?? false
    }
}

extension PlexSubtitleSearchResult: PlexListElement { static var plexListKey: String { "Stream" } }

/// Playback, artwork, track selection and subtitle requests.
/// Request builders return authenticated `URLRequest`s; never log their headers.
public protocol PlexMediaServing: Sendable {
    /// An authenticated request for artwork, resized by the server when a width or height is given.
    func imageRequest(path: String, width: Int?, height: Int?) throws -> URLRequest
    /// Artwork bytes, fetched through this service's transport so `PlexCachingTransport` can keep them for offline use.
    func imageData(path: String, width: Int?, height: Int?) async throws -> Data
    /// An authenticated request for a part's original file.
    /// - Throws: `PlexAPIError.unavailablePart` when the file is missing or has no key.
    func directPlayRequest(part: PlexMediaPart) throws -> URLRequest
    /// An authenticated HLS transcode request for players that can't play the original file.
    func streamRequest(_ options: PlexStreamOptions) throws -> URLRequest
    /// Ends a transcode session started with `streamRequest(_:)`.
    func stopStream(session: String) async throws
    /// An authenticated request for a part's BIF scrubbing thumbnails.
    func previewThumbnailsRequest(partID: String) throws -> URLRequest
    /// Saves the default audio and subtitle tracks for a part on the server.
    func selectStreams(partID: String, audioStreamID: String?, subtitleStreamID: String?) async throws
    /// Asks the server to search online subtitle providers for an item.
    func searchSubtitles(ratingKey: String, language: String) async throws -> [PlexSubtitleSearchResult]
    /// Asks the server to fetch a found subtitle and attach it to the item.
    func downloadSubtitle(ratingKey: String, result: PlexSubtitleSearchResult) async throws
}

extension PlexAPIService: PlexMediaServing {
    /// Server-resized artwork via `/photo/:/transcode`, or the original image when no size is given.
    /// Load it with `imageData(path:width:height:)`; caching it in `URLCache` would store the token header on disk.
    public func imageRequest(path: String, width: Int? = nil, height: Int? = nil) throws -> URLRequest {
        guard width != nil || height != nil else { return try configuration.request(path: path, accept: "image/*") }
        let query = [width.map { URLQueryItem(name: "width", value: String($0)) }, height.map { URLQueryItem(name: "height", value: String($0)) }]
            .compactMap { $0 } + [
                URLQueryItem(name: "minSize", value: "1"), URLQueryItem(name: "upscale", value: "1"), URLQueryItem(name: "url", value: path),
            ]
        return try configuration.request(path: "/photo/:/transcode", query: query, accept: "image/*")
    }

    /// Sends `imageRequest(path:width:height:)` through the service's transport.
    /// Prefer this to `URLCache`, which would also persist the request's token header to disk.
    public func imageData(path: String, width: Int? = nil, height: Int? = nil) async throws -> Data {
        try await executor.execute(imageRequest(path: path, width: width, height: height)).data
    }

    /// The original file, for players that support its container and codecs.
    public func directPlayRequest(part: PlexMediaPart) throws -> URLRequest {
        guard part.isPlayable, let key = part.key, !key.isEmpty else { throw PlexAPIError.unavailablePart(part.id ?? "") }
        return try resourceRequest(path: key)
    }

    /// An HLS (`start.m3u8`) transcode using the Generic profile plus an explicit HLS/H.264/AAC target,
    /// the approach Plezy uses for its MKV stream. Send it through a player that forwards the request headers.
    public func streamRequest(_ options: PlexStreamOptions) throws -> URLRequest {
        let original = options.maxVideoBitrateKbps == nil
        var profile = ["add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mpegts&videoCodec=h264&audioCodec=aac)"]
        if let bitrate = options.maxVideoBitrateKbps {
            profile.append("add-limitation(scope=videoCodec&scopeName=*&type=upperBound&name=video.bitrate&value=\(bitrate)&replace=true)")
        }
        let parameters: [(String, String?)] = [
            ("path", "/library/metadata/\(try PlexURLBuilder.segment(options.ratingKey))"),
            ("mediaIndex", String(options.mediaIndex)), ("partIndex", String(options.partIndex)),
            ("protocol", "hls"), ("fastSeek", "1"), ("directPlay", "0"), ("directStream", original ? "1" : "0"),
            ("directStreamAudio", "1"), ("subtitleSize", "100"), ("audioBoost", "100"), ("location", "lan"),
            ("session", options.session), ("X-Plex-Session-Identifier", options.session),
            ("maxVideoBitrate", options.maxVideoBitrateKbps.map(String.init)),
            ("offset", options.offset.map { String($0 / 1000) }),
            ("audioStreamID", options.audioStreamID), ("subtitleStreamID", options.subtitleStreamID),
            ("subtitles", options.subtitleStreamID == nil ? "none" : "burn"),
            ("X-Plex-Platform", "Generic"), ("X-Plex-Client-Profile-Extra", profile.joined(separator: "+")),
        ]
        // Plex's profile DSL needs ( ) * ' ! and , escaped, which URLQueryItem leaves literal.
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        let query = parameters.compactMap { name, value in
            value.flatMap { $0.addingPercentEncoding(withAllowedCharacters: allowed) }.map { "\(name)=\($0)" }
        }.joined(separator: "&")
        return try configuration.request(path: "/video/:/transcode/universal/start.m3u8?" + query, accept: "*/*")
    }

    /// Ends a transcode session so the server can free its resources.
    public func stopStream(session: String) async throws {
        try await send(PlexEndpoint(.get, "/video/:/transcode/universal/stop", query: [URLQueryItem(name: "session", value: session)]))
    }

    /// BIF scrubbing thumbnails for one part.
    public func previewThumbnailsRequest(partID: String) throws -> URLRequest {
        try resourceRequest(path: "/library/parts/\(try PlexURLBuilder.segment(partID))/indexes/sd")
    }

    /// Persists the default audio and subtitle tracks for a part; `"0"` turns subtitles off.
    public func selectStreams(partID: String, audioStreamID: String?, subtitleStreamID: String?) async throws {
        let query = [("audioStreamID", audioStreamID), ("subtitleStreamID", subtitleStreamID), ("allParts", "1")]
            .compactMap { name, value in value.map { URLQueryItem(name: name, value: $0) } }
        guard query.count > 1 else { return }
        try await send(PlexEndpoint(.put, "/library/parts/\(try PlexURLBuilder.segment(partID))", query: query))
    }

    /// `language` is an ISO 639-1 code such as `en`.
    public func searchSubtitles(ratingKey: String, language: String) async throws -> [PlexSubtitleSearchResult] {
        let response: PlexListEnvelope<PlexSubtitleSearchResult> = try await request(PlexEndpoint(.get, try subtitlesPath(ratingKey), query: [
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "hearingImpaired", value: "0"), URLQueryItem(name: "forced", value: "0"),
        ]))
        return response.elements
    }

    /// The server downloads the subtitle asynchronously; it appears as a new stream shortly afterwards.
    public func downloadSubtitle(ratingKey: String, result: PlexSubtitleSearchResult) async throws {
        let query = [
            ("key", result.key), ("codec", result.codec), ("language", result.language),
            ("hearingImpaired", result.hearingImpaired ? "1" : "0"), ("forced", result.forced ? "1" : "0"),
            ("providerTitle", result.providerTitle),
        ].compactMap { name, value in value.map { URLQueryItem(name: name, value: $0) } }
        try await send(PlexEndpoint(.put, try subtitlesPath(ratingKey), query: query))
    }

    private func subtitlesPath(_ ratingKey: String) throws -> String {
        "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))/subtitles"
    }
}
