import Foundation
@testable import SwiftfinLauncher

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

/// Holds requests until the test explicitly resolves them, including after their task is
/// cancelled. This exercises services that finish work without observing cancellation.
actor DelayedJellyfinLibraryService: JellyfinLibraryServicing {
    nonisolated let isAvailable = true
    private var requestCount = 0
    private var requests: [Int: CheckedContinuation<JellyfinMovieMatch?, Error>] = [:]
    private var requestWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    func findMovie(title: String, tmdbID: Int) async throws -> JellyfinMovieMatch? {
        try await withCheckedThrowingContinuation { continuation in
            requests[requestCount] = continuation
            requestCount += 1
            let ready = requestWaiters.filter { $0.count <= requestCount }
            requestWaiters.removeAll { $0.count <= requestCount }
            ready.forEach { $0.continuation.resume() }
        }
    }

    func waitForRequests(_ count: Int) async {
        guard requestCount < count else { return }
        await withCheckedContinuation { continuation in
            requestWaiters.append((count, continuation))
        }
    }

    func completeRequest(_ index: Int, with result: Result<JellyfinMovieMatch?, Error>) {
        guard let continuation = requests.removeValue(forKey: index) else {
            preconditionFailure("The requested Jellyfin lookup has not started or already completed.")
        }
        continuation.resume(with: result)
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
