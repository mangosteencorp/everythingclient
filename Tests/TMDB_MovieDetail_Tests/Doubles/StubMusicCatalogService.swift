import Foundation
@testable import TMDB_MovieDetail

/// Stands in for Apple Music. Every MusicKit entry point the view model uses is a stored value or a
/// closure here, so the OST flow can be driven without a signed-in device.
final class StubMusicCatalogService: MusicCatalogServiceProtocol, @unchecked Sendable {
    var authorization: MusicCatalogAuthorization
    var requestedAuthorization: MusicCatalogAuthorization
    var searchResult: Result<[MovieOSTAlbumDisplayModel], Error>

    private(set) var requestAuthorizationCallCount = 0
    private(set) var searchedTerms: [String] = []
    private(set) var searchedLimits: [Int] = []

    init(
        authorization: MusicCatalogAuthorization = .authorized,
        requestedAuthorization: MusicCatalogAuthorization = .authorized,
        searchResult: Result<[MovieOSTAlbumDisplayModel], Error> = .success([])
    ) {
        self.authorization = authorization
        self.requestedAuthorization = requestedAuthorization
        self.searchResult = searchResult
    }

    var currentAuthorization: MusicCatalogAuthorization { authorization }

    func requestAuthorization() async -> MusicCatalogAuthorization {
        requestAuthorizationCallCount += 1
        authorization = requestedAuthorization
        return requestedAuthorization
    }

    func searchAlbums(term: String, limit: Int) async throws -> [MovieOSTAlbumDisplayModel] {
        searchedTerms.append(term)
        searchedLimits.append(limit)
        return try searchResult.get()
    }
}

extension MovieOSTAlbumDisplayModel {
    static func stub(id: String = "1", title: String) -> MovieOSTAlbumDisplayModel {
        MovieOSTAlbumDisplayModel(
            id: id,
            title: title,
            artistName: "Hans Zimmer",
            trackCount: 12,
            artwork: nil,
            url: URL(string: "https://music.apple.com/album/\(id)")
        )
    }
}

struct StubError: Error, LocalizedError {
    var errorDescription: String? { "stub failure" }
}
