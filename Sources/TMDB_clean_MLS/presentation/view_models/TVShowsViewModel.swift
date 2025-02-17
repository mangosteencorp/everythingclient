import Combine
class TVShowsViewModel: ObservableObject {
    @Published var tvShows: [TVShowEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchTVShowsUseCase: FetchTVShowsUseCase

    init(fetchTVShowsUseCase: FetchTVShowsUseCase) {
        self.fetchTVShowsUseCase = fetchTVShowsUseCase
    }

    func fetchTVShows() {
        isLoading = true
        errorMessage = nil

        Task {
            let result = await fetchTVShowsUseCase.execute()
            await MainActor.run {
                self.isLoading = false
                switch result {
                case let .success(tvShows):
                    self.tvShows = tvShows
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
} 
