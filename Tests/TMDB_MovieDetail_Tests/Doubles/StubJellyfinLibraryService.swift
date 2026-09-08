import Foundation
@testable import third_party

/// Stands in for Swiftfin's signed-in Jellyfin session, which needs a real server to exist.
final class StubJellyfinLibraryService: JellyfinLibraryServicing, @unchecked Sendable {
    var available: Bool
    var findResult: Result<JellyfinMovieMatch?, Error>

    private(set) var searchedTitles: [String] = []
    private(set) var searchedTMDBIDs: [Int] = []

    init(
        available: Bool = true,
        findResult: Result<JellyfinMovieMatch?, Error> = .success(nil)
    ) {
        self.available = available
        self.findResult = findResult
    }

    var isAvailable: Bool { available }

    func findMovie(title: String, tmdbID: Int) async throws -> JellyfinMovieMatch? {
        searchedTitles.append(title)
        searchedTMDBIDs.append(tmdbID)
        return try findResult.get()
    }
}

extension JellyfinMovieMatch {
    static func stub(
        id: String = "item-1",
        title: String = "Dune",
        runtimeSeconds: Double? = 9315,
        playedFraction: Double = 0,
        resumeSeconds: Double = 0,
        isPlayed: Bool = false
    ) -> JellyfinMovieMatch {
        JellyfinMovieMatch(
            id: id,
            title: title,
            runtimeSeconds: runtimeSeconds,
            playedFraction: playedFraction,
            resumeSeconds: resumeSeconds,
            isPlayed: isPlayed
        )
    }
}
