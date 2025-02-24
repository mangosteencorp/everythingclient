import CoreFeatures
import SwiftUI

class MoviesViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchMoviesUseCase: FetchMoviesUseCase
    private let analyticsTracker: AnalyticsTracker?

    init(fetchMoviesUseCase: FetchMoviesUseCase,
         analyticsTracker: AnalyticsTracker? = nil) {
        self.fetchMoviesUseCase = fetchMoviesUseCase
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
                        screenClass: "MovieListContent"
                    ))
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
