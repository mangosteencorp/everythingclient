import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

typealias MovieCastingState = LoadState<MovieCredits>

@MainActor
class MovieCastingViewModel: ObservableObject {
    @Published var state: MovieCastingState = .initial

    private let apiService: TMDBAPIService
    init(apiService: TMDBAPIService) {
        self.apiService = apiService
    }

    func load(movieId: Int) async {
        guard state.isInitial else { return }
        await fetch(movieId: movieId)
    }

    func reload(movieId: Int) async {
        guard !state.isLoading else { return }
        await fetch(movieId: movieId)
    }

    private func fetch(movieId: Int) async {
        state = .loading
        let result: Result<MovieCreditsModel, TMDBAPIError> = await apiService.request(.credits(movie: movieId))
        guard !Task.isCancelled else {
            state = .initial
            return
        }
        switch result {
        case let .success(creditsModel):
            state = .success(Self.credits(from: creditsModel))
        case let .failure(error):
            state = .error(error.localizedDescription)
        }
    }

    private static func credits(from model: MovieCreditsModel) -> MovieCredits {
        MovieCredits(
            id: model.id,
            cast: model.cast.map { castMember in
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
            crew: model.crew.map { crewMember in
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
    }
}
