import Combine
import SwiftUI
import TMDB_Shared_Backend

enum MovieCastingState {
    case loading
    case success(MovieCredits)
    case error(String)
}

class MovieCastingViewModel: ObservableObject {
    @Published var state: MovieCastingState

    private var cancellables = Set<AnyCancellable>()
    private let apiService: TMDBAPIService
    init(apiService: TMDBAPIService) {
        self.apiService = apiService
        state = .loading
    }

    func fetchMovieCredits(movieId: Int) {
        state = .loading
        Task {
            let result: Result<MovieCreditsModel, TMDBAPIError> = await apiService.request(.credits(movie: movieId))
            DispatchQueue.main.async {
                switch result {
                case let .success(creditsModel):
                    let credits = MovieCredits(
                        id: creditsModel.id,
                        cast: creditsModel.cast.map { castMember in
                            People(
                                id: castMember.id,
                                name: castMember.name,
                                character: castMember.character,
                                department: nil,
                                profilePath: castMember.profile_path,
                                knownForDepartment: castMember.known_for_department,
                                popularity: castMember.popularity
                            )
                        },
                        crew: creditsModel.crew.map { crewMember in
                            People(
                                id: crewMember.id,
                                name: crewMember.name,
                                character: nil,
                                department: crewMember.department,
                                profilePath: crewMember.profile_path,
                                knownForDepartment: crewMember.known_for_department,
                                popularity: crewMember.popularity
                            )
                        }
                    )
                    self.state = .success(credits)
                case let .failure(error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
}
