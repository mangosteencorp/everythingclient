import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI
struct MovieCreditSection: View {
    let movieId: Int
    // avoiding The problem that every time the parent view redraws, a new instance of MovieCastingViewModel is created
    // because it's initialized in the init method.
    @ObservedObject var creditsViewModel: MovieCastingViewModel
    init(movieId: Int, creditsViewModel: MovieCastingViewModel) {
        self.movieId = movieId
        self.creditsViewModel = creditsViewModel
    }

    var body: some View {
        Section {
            switch creditsViewModel.state {
            case .loading:
                RedactedMovieCrosslinePeopleRow()
            case let .success(credits):
                // Display the credits information
                MovieCrosslinePeopleRow(title: L10n.castSectionTitle, peoples: credits.cast)
                MovieCrosslinePeopleRow(title: L10n.crewSectionTitle, peoples: credits.crew)
            case let .error(errorMessage):
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            }
        }.onFirstAppear {
            creditsViewModel.fetchMovieCredits(movieId: movieId)
        }
    }
}

#if DEBUG
#Preview {
    MovieCreditSection(
        movieId: 939_243,
        creditsViewModel: MovieCastingViewModel(
            apiService: TMDBAPIService(apiKey: debugTMDBAPIKey)
        )
    )
}
#endif
