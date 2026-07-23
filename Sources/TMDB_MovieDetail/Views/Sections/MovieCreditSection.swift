import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
struct MovieCreditSection<Route: Hashable>: View {
    let movieId: Int
    // avoiding The problem that every time the parent view redraws, a new instance of MovieCastingViewModel is created
    // because it's initialized in the init method.
    @ObservedObject var creditsViewModel: MovieCastingViewModel
    let personRouteBuilder: ((Int) -> Route)?

    init(
        movieId: Int,
        creditsViewModel: MovieCastingViewModel,
        personRouteBuilder: ((Int) -> Route)? = nil
    ) {
        self.movieId = movieId
        self.creditsViewModel = creditsViewModel
        self.personRouteBuilder = personRouteBuilder
    }

    var body: some View {
        Section {
            switch creditsViewModel.state {
            case .loading:
                RedactedMovieCrosslinePeopleRow()
            case let .success(credits):
                // Display the credits information
                MovieCrosslinePeopleRow(
                    title: L10n.castSectionTitle,
                    peoples: credits.cast,
                    personRouteBuilder: personRouteBuilder
                )
                MovieCrosslinePeopleRow(
                    title: L10n.crewSectionTitle,
                    peoples: credits.crew,
                    personRouteBuilder: personRouteBuilder
                )
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
@available(iOS 16.0, *)
#Preview {
    MovieCreditSection(
        movieId: 939_243,
        creditsViewModel: MovieCastingViewModel(
            apiService: TMDBAPIService(apiKey: debugTMDBAPIKey)
        ),
        personRouteBuilder: { $0 }
    )
}
#endif
