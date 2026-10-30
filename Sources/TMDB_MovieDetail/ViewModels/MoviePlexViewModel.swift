import Combine
import PlexIntegration

enum MoviePlexState: Equatable {
    /// Nobody is signed in to Plex, so the block stays out of the page instead of advertising a server the user does
    /// not have.
    case unavailable
    case loading
    case found(PlexMovieMatch)
    case notInLibrary
    case error(String)
}

struct MoviePlexQuery: Equatable {
    let title: String
    let year: Int?

    init(title: String, year: Int?) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.year = year
    }
}

/// `MovieJellyfinViewModel`'s counterpart for the app's Plex session.
@MainActor
final class MoviePlexViewModel: ObservableObject {
    /// Hidden until the session is known to exist, so signed-out users never see a spinner flash by.
    @Published var state: MoviePlexState = .unavailable

    /// Nothing to show for a movie the user cannot watch, or a server they are not signed in to.
    var isVisible: Bool {
        switch state {
        case .unavailable, .notInLibrary: false
        case .loading, .found, .error: true
        }
    }

    private let service: any PlexLibraryServicing
    private var loadedQuery: MoviePlexQuery?
    private var generation = 0

    init(service: any PlexLibraryServicing = PlexLibraryService()) {
        self.service = service
    }

    func load(title: String, year: Int?, forceRefresh: Bool = false) async {
        let query = MoviePlexQuery(title: title, year: year)
        guard !Task.isCancelled, !query.title.isEmpty, forceRefresh || loadedQuery != query else { return }

        generation += 1
        let requestGeneration = generation
        loadedQuery = query
        defer {
            // A cancelled current lookup must be retryable. An older lookup cannot clear the
            // newer request's dedupe marker, even if its service ignores cancellation.
            if Task.isCancelled, generation == requestGeneration {
                loadedQuery = nil
            }
        }

        let isSignedIn = await service.isSignedIn
        guard canPublish(requestGeneration, query: query) else { return }
        guard isSignedIn else {
            state = .unavailable
            return
        }
        state = .loading

        do {
            let match = try await service.findMovie(title: query.title, year: query.year)
            guard canPublish(requestGeneration, query: query) else { return }
            state = match.map(MoviePlexState.found) ?? .notInLibrary
        } catch {
            guard canPublish(requestGeneration, query: query) else { return }
            guard !(error is CancellationError) else {
                loadedQuery = nil
                return
            }
            state = (error as? PlexLibraryError) == .notConnected ? .unavailable : .error(error.localizedDescription)
        }
    }

    func reload(title: String, year: Int?) async {
        await load(title: title, year: year, forceRefresh: true)
    }

    func reloadIfCurrent(title: String, year: Int?) async {
        guard loadedQuery == MoviePlexQuery(title: title, year: year) else { return }
        await reload(title: title, year: year)
    }

    private func canPublish(_ requestGeneration: Int, query: MoviePlexQuery) -> Bool {
        !Task.isCancelled && generation == requestGeneration && loadedQuery == query
    }
}
