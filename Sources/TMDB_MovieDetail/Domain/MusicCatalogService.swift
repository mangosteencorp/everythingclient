import Foundation
import MusicKit

/// Authorization outcome, restated in the module's own vocabulary so callers and tests never have
/// to build a `MusicAuthorization.Status` (which has no public initialiser).
public enum MusicCatalogAuthorization: Sendable {
    case notDetermined
    case denied
    case authorized
}

/// One album from the music catalog, already flattened off MusicKit's `Album` so that nothing
/// downstream of the service has to touch a MusicKit request type.
public struct MovieOSTAlbumDisplayModel: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let artistName: String
    public let trackCount: Int?
    public let artwork: Artwork?
    public let url: URL?

    public init(
        id: String,
        title: String,
        artistName: String,
        trackCount: Int?,
        artwork: Artwork?,
        url: URL?
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.trackCount = trackCount
        self.artwork = artwork
        self.url = url
    }
}

/// The seam between `MovieOSTViewModel` and MusicKit.
///
/// MusicKit only exposes statics (`MusicAuthorization.currentStatus`, `MusicAuthorization.request()`)
/// and a request type that always talks to Apple Music, so the view model had no way to be exercised
/// without a signed-in device. Everything the view model needs is behind this protocol instead, and
/// the tests inject a stub.
public protocol MusicCatalogServiceProtocol: Sendable {
    var currentAuthorization: MusicCatalogAuthorization { get }
    func requestAuthorization() async -> MusicCatalogAuthorization
    /// Raw catalog hits for `term`; soundtrack filtering stays in the view model.
    func searchAlbums(term: String, limit: Int) async throws -> [MovieOSTAlbumDisplayModel]
}

/// The real MusicKit-backed implementation.
public struct MusicKitCatalogService: MusicCatalogServiceProtocol {
    public init() {}

    public var currentAuthorization: MusicCatalogAuthorization {
        MusicCatalogAuthorization(MusicAuthorization.currentStatus)
    }

    public func requestAuthorization() async -> MusicCatalogAuthorization {
        MusicCatalogAuthorization(await MusicAuthorization.request())
    }

    public func searchAlbums(term: String, limit: Int) async throws -> [MovieOSTAlbumDisplayModel] {
        var request = MusicCatalogSearchRequest(term: term, types: [Album.self])
        request.limit = limit
        return try await request.response().albums.map { album in
            MovieOSTAlbumDisplayModel(
                id: album.id.rawValue,
                title: album.title,
                artistName: album.artistName,
                trackCount: album.trackCount,
                artwork: album.artwork,
                url: album.url
            )
        }
    }
}

private extension MusicCatalogAuthorization {
    init(_ status: MusicAuthorization.Status) {
        switch status {
        case .authorized: self = .authorized
        case .notDetermined: self = .notDetermined
        // `.restricted` offers the user the same dead end as `.denied`.
        case .denied, .restricted: self = .denied
        @unknown default: self = .denied
        }
    }
}
