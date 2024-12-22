import SwiftUI
class MoviesViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fetchMoviesUseCase: FetchMoviesUseCase
    
    init(fetchMoviesUseCase: FetchMoviesUseCase) {
        self.fetchMoviesUseCase = fetchMoviesUseCase
    }
    
    func fetchMovies() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await fetchMoviesUseCase.execute()
            await MainActor.run {
                self.isLoading = false
                switch result {
                case .success(let movies):
                    self.movies = movies
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
