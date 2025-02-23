import CoreFeatures
import SwiftUI

class MoviesViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchMoviesUseCase: FetchMoviesUseCase
    private let analyticsTracker: AnalyticsTracker?
    private let screenName: String

    init(fetchMoviesUseCase: FetchMoviesUseCase,
         analyticsTracker: AnalyticsTracker? = nil,
         screenName: String) {
        self.fetchMoviesUseCase = fetchMoviesUseCase
        self.analyticsTracker = analyticsTracker
        self.screenName = screenName
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
                        screenName: screenName,
                        screenClass: "MovieListPage",
                        contentType: "movieList"
                    ))
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
