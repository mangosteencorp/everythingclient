import CoreFeatures
import SwiftUI

class TVFeedViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchMoviesUseCase: FetchMoviesUseCase
    private let toggleTVShowFavoriteUseCase: ToggleTVShowFavoriteUseCase?
    private let analyticsTracker: AnalyticsTracker?

    init(fetchMoviesUseCase: FetchMoviesUseCase,
         toggleTVShowFavoriteUseCase: ToggleTVShowFavoriteUseCase? = nil,
         analyticsTracker: AnalyticsTracker? = nil) {
        self.fetchMoviesUseCase = fetchMoviesUseCase
        self.toggleTVShowFavoriteUseCase = toggleTVShowFavoriteUseCase
        self.analyticsTracker = analyticsTracker
    }

    func fetchMovies() {
        isLoading = true
        errorMessage = nil

        Task {
            let result = await fetchMoviesUseCase.execute()
            await MainActor.run {
                self.isLoading = false
                switch result {
                case let .success(movies):
                    self.movies = movies
                    analyticsTracker?.trackPageView(parameters: PageViewParameters(
                        screenName: "ListTVShows",
                        screenClass: "TVShowListContent"
                    ))
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func toggleFavorite(for movieId: Int) async {
        guard let toggleUseCase = toggleTVShowFavoriteUseCase else {
            await MainActor.run {
                self.errorMessage = "Favorite functionality not available"
            }
            return
        }
        
        // Find the movie and toggle its favorite status
        guard let movieIndex = movies.firstIndex(where: { $0.id == movieId }) else { return }
        let currentFavoriteStatus = movies[movieIndex].isFavorite
        let newFavoriteStatus = !currentFavoriteStatus
        
        // Optimistically update UI
        await MainActor.run {
            self.movies[movieIndex].isFavorite = newFavoriteStatus
        }
        
        // Make API call
        let result = await toggleUseCase.execute(tvShowId: movieId, isFavorite: newFavoriteStatus)
        
        switch result {
        case .success:
            // Success - UI already updated optimistically
            break
        case let .failure(error):
            // Revert UI change on failure
            await MainActor.run {
                self.movies[movieIndex].isFavorite = currentFavoriteStatus
                self.errorMessage = "Failed to update favorite: \(error.localizedDescription)"
            }
        }
    }
}
