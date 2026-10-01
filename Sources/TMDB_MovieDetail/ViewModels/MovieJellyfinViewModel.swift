import Combine
import SwiftUI
import third_party

public enum MovieJellyfinState: Equatable {
    /// SwiftfinLib is not in this build, or no Jellyfin server is connected. Either way the section
    /// stays out of the page instead of advertising a server the user does not have.
    case unavailable
    case loading
    case found(JellyfinMovieMatch)
    case notInLibrary
    case error(String)
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
    private var loadedMovieTitle: String?

    public init(service: any JellyfinLibraryServicing = SwiftfinJellyfinLibraryService()) {
        self.service = service
        // Settled before the first render so a build without Swiftfin never flashes the spinner.
        state = service.isAvailable ? .loading : .unavailable
    }

    func load(title: String, tmdbID: Int) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, loadedMovieTitle != trimmedTitle else { return }

        loadedMovieTitle = trimmedTitle
        await search(title: trimmedTitle, tmdbID: tmdbID)
    }

    func reload(title: String, tmdbID: Int) async {
        guard state != .loading else { return }
        await search(title: title.trimmingCharacters(in: .whitespacesAndNewlines), tmdbID: tmdbID)
    }

    private func search(title: String, tmdbID: Int) async {
        guard service.isAvailable else {
            state = .unavailable
            return
        }
        state = .loading

        do {
            let match = try await service.findMovie(title: title, tmdbID: tmdbID)
            state = match.map(MovieJellyfinState.found) ?? .notInLibrary
        } catch JellyfinLibraryError.notConnected {
            state = .unavailable
        } catch {
            // Leaving the page cancels the search. Forget the title so re-entering searches again
            // instead of showing a cancellation as a failure.
            guard !Task.isCancelled else {
                loadedMovieTitle = nil
                state = .loading
                return
            }
            state = .error(error.localizedDescription)
        }
    }
}
