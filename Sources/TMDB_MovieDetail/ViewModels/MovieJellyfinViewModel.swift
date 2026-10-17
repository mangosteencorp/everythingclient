import Combine
import SwiftfinLauncher
import SwiftUI

public enum MovieJellyfinState: Equatable {
    /// SwiftfinLib is not in this build, or no Jellyfin server is connected. Either way the section
    /// stays out of the page instead of advertising a server the user does not have.
    case unavailable
    case loading
    case found(JellyfinMovieMatch)
    case notInLibrary
    case error(String)
}

struct MovieJellyfinQuery: Equatable {
    let title: String
    let tmdbID: Int

    init(title: String, tmdbID: Int) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tmdbID = tmdbID
    }
}

@MainActor
public final class MovieJellyfinViewModel: ObservableObject {
    @Published var state: MovieJellyfinState

    /// Nothing to show for a movie the user cannot watch, or a server they are not signed in to.
    var isVisible: Bool {
        switch state {
        case .unavailable, .notInLibrary: false
        case .loading, .found, .error: true
        }
    }

    private let service: any JellyfinLibraryServicing
    private var loadedQuery: MovieJellyfinQuery?
    private var generation = 0

    public init(service: any JellyfinLibraryServicing = SwiftfinJellyfinLibraryService()) {
        self.service = service
        // Settled before the first render so a build without Swiftfin never flashes the spinner.
        state = service.isAvailable ? .loading : .unavailable
    }

    func load(title: String, tmdbID: Int, forceRefresh: Bool = false) async {
        let query = MovieJellyfinQuery(title: title, tmdbID: tmdbID)
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

        guard canPublish(requestGeneration, query: query) else { return }
        guard service.isAvailable else {
            state = .unavailable
            return
        }
        state = .loading

        do {
            let match = try await service.findMovie(title: query.title, tmdbID: query.tmdbID)
            guard canPublish(requestGeneration, query: query) else { return }
            state = match.map(MovieJellyfinState.found) ?? .notInLibrary
        } catch {
            guard canPublish(requestGeneration, query: query) else { return }
            guard !(error is CancellationError) else {
                loadedQuery = nil
                return
            }
            state = (error as? JellyfinLibraryError) == .notConnected ? .unavailable : .error(error.localizedDescription)
        }
    }

    func reload(title: String, tmdbID: Int) async {
        await load(title: title, tmdbID: tmdbID, forceRefresh: true)
    }

    func reloadIfCurrent(title: String, tmdbID: Int) async {
        guard loadedQuery == MovieJellyfinQuery(title: title, tmdbID: tmdbID) else { return }
        await reload(title: title, tmdbID: tmdbID)
    }

    private func canPublish(_ requestGeneration: Int, query: MovieJellyfinQuery) -> Bool {
        !Task.isCancelled && generation == requestGeneration && loadedQuery == query
    }
}
