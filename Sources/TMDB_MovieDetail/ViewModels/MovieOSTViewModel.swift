import Combine
import SwiftUI

public enum MovieOSTState {
    case notDetermined
    case denied
    case loading
    case success([MovieOSTAlbumDisplayModel])
    case empty
    case error(String)
}

@MainActor
public class MovieOSTViewModel: ObservableObject {
    /// How many catalog hits to ask for before soundtrack filtering, and how many to keep after.
    private static let searchLimit = 10
    private static let displayLimit = 5

    @Published var state: MovieOSTState = .notDetermined

    private let catalogService: MusicCatalogServiceProtocol
    private var loadedMovieTitle: String?

    public init(catalogService: MusicCatalogServiceProtocol = MusicKitCatalogService()) {
        self.catalogService = catalogService
    }

    func load(for movieTitle: String) async {
        let trimmedTitle = movieTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard loadedMovieTitle != trimmedTitle || shouldReloadForCurrentAuthorization else { return }

        loadedMovieTitle = trimmedTitle
        await handleAuthorization(catalogService.currentAuthorization, movieTitle: trimmedTitle)
    }

    func requestAuthorization() async {
        await handleAuthorization(await catalogService.requestAuthorization())
    }

    private var shouldReloadForCurrentAuthorization: Bool {
        switch state {
        case .notDetermined, .denied:
            return true
        default:
            return false
        }
    }

    private func handleAuthorization(_ authorization: MusicCatalogAuthorization, movieTitle: String? = nil) async {
        switch authorization {
        case .authorized:
            guard let movieTitle = movieTitle ?? loadedMovieTitle else {
                state = .notDetermined
                return
            }
            await searchSoundtrack(for: movieTitle)
        case .notDetermined:
            state = .notDetermined
        case .denied:
            state = .denied
        }
    }

    private func searchSoundtrack(for movieTitle: String) async {
        state = .loading

        do {
            let albums = try await catalogService.searchAlbums(
                term: MovieOSTSearchQueryBuilder.searchTerm(for: movieTitle),
                limit: Self.searchLimit
            )
            .filter { MovieOSTSearchQueryBuilder.isLikelySoundtrackAlbum(title: $0.title) }
            .prefix(Self.displayLimit)

            state = albums.isEmpty ? .empty : .success(Array(albums))
        } catch {
            // Leaving the page cancels the search. Forget the title so re-entering searches again
            // instead of showing a cancellation as a failure.
            guard !Task.isCancelled else {
                loadedMovieTitle = nil
                return
            }
            state = .error(error.localizedDescription)
        }
    }
}
