import Foundation

/// Which parts of a split file a download plan includes.
public enum PlexDownloadPartSelection: Sendable {
    /// Matches Plezy's original-file selection: first available part of the chosen version.
    case firstPlayable
    /// Explicit extension for split files: require every part, preserving server order.
    case allParts
}

/// Authenticated original-file requests only. The app owns background transfers, persistence,
/// resumption, storage, artwork caching, and offline playback/progress synchronization.
public struct PlexDownloadPlan: Sendable {
    /// The planned item.
    public let ratingKey: String
    /// The media version actually chosen, after fallback.
    public let mediaIndex: Int
    /// Files to download, in playback order.
    public let parts: [PlexDownloadPart]
}

/// One original file to download.
public struct PlexDownloadPart: Sendable {
    /// The part's position within its media version.
    public let partIndex: Int
    /// The part's metadata, including size and streams.
    public let part: PlexMediaPart
    /// The authenticated request for the file. Its headers contain the server token.
    public let request: URLRequest
    /// External subtitle files for this part.
    public let subtitles: [PlexSubtitleDownload]
}

/// One external subtitle file to download next to the video.
public struct PlexSubtitleDownload: Sendable {
    /// The subtitle stream.
    public let stream: PlexMediaStream
    /// File extension for the saved sidecar, such as `srt` or `ass`.
    public let fileExtension: String
    /// The authenticated UTF-8 subtitle request.
    public let request: URLRequest
}

/// Turns item metadata into download requests without performing any transfer.
public protocol PlexDownloadPlanning: Sendable {
    /// Plans the files for one media version of an item.
    /// - Throws: `PlexAPIError.noDownloadableMedia` or `.unavailablePart` when files are missing.
    func plan(
        for metadata: PlexMetadata, mediaIndex: Int, selection: PlexDownloadPartSelection
    ) throws -> PlexDownloadPlan
}

/// The default planner for one server.
public struct PlexDownloadPlanner: PlexDownloadPlanning {
    private let configuration: PlexServerConfiguration

    /// Creates a planner whose requests target `configuration`'s server.
    public init(configuration: PlexServerConfiguration) { self.configuration = configuration }

    /// Invalid version indexes fall back to index zero; unavailable versions fall back to the
    /// first version with a playable keyed part. Entirely unavailable media fails explicitly.
    public func plan(
        for metadata: PlexMetadata, mediaIndex: Int = 0, selection: PlexDownloadPartSelection = .allParts
    ) throws -> PlexDownloadPlan {
        let versions = metadata.media
        guard !versions.isEmpty else { throw PlexAPIError.noDownloadableMedia }
        let requested = versions.indices.contains(mediaIndex) ? mediaIndex : 0
        let chosen = versions[requested].parts.contains(where: Self.isDownloadable)
            ? requested : versions.firstIndex { $0.parts.contains(where: Self.isDownloadable) }
        guard let chosen else { throw PlexAPIError.noDownloadableMedia }
        let version = versions[chosen]
        let indexes: [Int]
        switch selection {
        case .firstPlayable:
            guard let index = version.parts.firstIndex(where: Self.isDownloadable) else { throw PlexAPIError.noDownloadableMedia }
            indexes = [index]
        case .allParts:
            indexes = Array(version.parts.indices)
        }

        let parts = try indexes.map { index in
            let part = version.parts[index]
            guard Self.isDownloadable(part), let key = part.key else {
                throw PlexAPIError.unavailablePart(part.id ?? String(index))
            }
            let request = try configuration.request(path: key, accept: "*/*")
            let subtitles = try part.streams.filter(\.isExternalSubtitle).map(subtitleDownload)
            return PlexDownloadPart(partIndex: index, part: part, request: request, subtitles: subtitles)
        }
        return PlexDownloadPlan(ratingKey: metadata.ratingKey, mediaIndex: chosen, parts: parts)
    }

    private static func isDownloadable(_ part: PlexMediaPart) -> Bool { part.isPlayable && part.key?.isEmpty == false }

    private func subtitleDownload(_ stream: PlexMediaStream) throws -> PlexSubtitleDownload {
        guard let key = stream.key, var components = URLComponents(string: key) else { throw PlexAPIError.invalidPath }
        let fileExtension = Self.subtitleExtension(codec: stream.codec)
        components.percentEncodedPath += "." + fileExtension
        guard let path = components.string else { throw PlexAPIError.invalidPath }
        let request = try configuration.request(path: path, query: [URLQueryItem(name: "encoding", value: "utf-8")], accept: "*/*")
        return PlexSubtitleDownload(stream: stream, fileExtension: fileExtension, request: request)
    }

    static func subtitleExtension(codec: String?) -> String {
        switch codec?.lowercased() {
        case "ass", "ssa": return "ass"
        case "webvtt", "vtt": return "vtt"
        case "pgs", "hdmv_pgs_subtitle": return "sup"
        case "dvd_subtitle", "dvdsub": return "sub"
        default: return "srt"
        }
    }
}
