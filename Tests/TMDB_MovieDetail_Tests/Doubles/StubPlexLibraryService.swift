import Foundation
import PlexIntegration

/// Stands in for the app's signed-in Plex session, which needs a real server to exist.
final class StubPlexLibraryService: PlexLibraryServicing, @unchecked Sendable {
    var signedIn: Bool
    var findResult: Result<PlexMovieMatch?, Error>

    private(set) var searchedTitles: [String] = []
    private(set) var searchedYears: [Int?] = []

    init(signedIn: Bool = true, findResult: Result<PlexMovieMatch?, Error> = .success(nil)) {
        self.signedIn = signedIn
        self.findResult = findResult
    }

    var isSignedIn: Bool {
        get async { signedIn }
    }

    func findMovie(title: String, year: Int?) async throws -> PlexMovieMatch? {
        searchedTitles.append(title)
        searchedYears.append(year)
        return try findResult.get()
    }
}

/// Holds requests until the test explicitly resolves them, including after their task is
/// cancelled. This exercises services that finish work without observing cancellation.
actor DelayedPlexLibraryService: PlexLibraryServicing {
    nonisolated let isSignedIn = true
    private var requestCount = 0
    private var requests: [Int: CheckedContinuation<PlexMovieMatch?, Error>] = [:]
    private var requestWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    func findMovie(title: String, year: Int?) async throws -> PlexMovieMatch? {
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

    func completeRequest(_ index: Int, with result: Result<PlexMovieMatch?, Error>) {
        guard let continuation = requests.removeValue(forKey: index) else {
            preconditionFailure("The requested Plex lookup has not started or already completed.")
        }
        continuation.resume(with: result)
    }
}

extension PlexMovieMatch {
    static func stub(
        id: String = "42",
        title: String = "Dune",
        runtimeSeconds: Double? = 9315,
        playedFraction: Double = 0,
        resumeSeconds: Double = 0,
        isPlayed: Bool = false
    ) -> PlexMovieMatch {
        PlexMovieMatch(
            id: id,
            title: title,
            runtimeSeconds: runtimeSeconds,
            playedFraction: playedFraction,
            resumeSeconds: resumeSeconds,
            isPlayed: isPlayed
        )
    }
}
