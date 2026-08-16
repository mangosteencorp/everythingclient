import Combine
import MusicKit
import SwiftUI

public enum MovieOSTState {
    case notDetermined
    case denied
    case loading
    case success([MovieOSTAlbumDisplayModel])
    case empty
    case error(String)
}

public struct MovieOSTAlbumDisplayModel: Identifiable {
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

@MainActor
public class MovieOSTViewModel: ObservableObject {
    @Published var state: MovieOSTState = .notDetermined

    private var loadedMovieTitle: String?

    public init() {}

    func load(for movieTitle: String) async {
        let trimmedTitle = movieTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard loadedMovieTitle != trimmedTitle || shouldReloadForCurrentAuthorization else { return }

        loadedMovieTitle = trimmedTitle
        await handleAuthorizationStatus(MusicAuthorization.currentStatus, movieTitle: trimmedTitle)
    }

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        await handleAuthorizationStatus(status)
    }

    private var shouldReloadForCurrentAuthorization: Bool {
        switch state {
        case .notDetermined, .denied:
            return true
        default:
            return false
        }
    }

    private func handleAuthorizationStatus(_ status: MusicAuthorization.Status, movieTitle: String? = nil) async {
        switch status {
        case .authorized:
            guard let movieTitle = movieTitle ?? loadedMovieTitle else {
                state = .notDetermined
                return
            }
            await searchSoundtrack(for: movieTitle)
        case .notDetermined:
            state = .notDetermined
        case .denied, .restricted:
            state = .denied
        @unknown default:
            state = .denied
        }
    }

    private func searchSoundtrack(for movieTitle: String) async {
        state = .loading

        do {
            let term = MovieOSTSearchQueryBuilder.searchTerm(for: movieTitle)
            var request = MusicCatalogSearchRequest(term: term, types: [Album.self])
            request.limit = 10
            let response = try await request.response()

            let albums = response.albums
                .filter { MovieOSTSearchQueryBuilder.isLikelySoundtrackAlbum(title: $0.title) }
                .prefix(5)
                .map { album in
                    MovieOSTAlbumDisplayModel(
                        id: album.id.rawValue,
                        title: album.title,
                        artistName: album.artistName,
                        trackCount: album.trackCount,
                        artwork: album.artwork,
                        url: album.url
                    )
                }

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
