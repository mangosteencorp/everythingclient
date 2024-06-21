// DMS: Dimilian Simplified View

import SwiftUI
import Foundation
import Combine

class NowPlayingViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    
    public init(initialMovies: [Movie] = []) {
        movies = initialMovies
    }
    
    func fetchNowPlayingMovies() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await self.apiService.fetchNowPlayingMovies()
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.movies = response.results
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

@available(iOS 15, macOS 10.15, *)
struct DMSNowPlayingView: View {
    @StateObject private var viewModel = NowPlayingViewModel(initialMovies: Array(repeating: sampleEmptyMovie, count: 10))
    let loading: Bool
    init(loading: Bool = false) {
        self.loading = loading
        if loading{
            viewModel.fetchNowPlayingMovies()
        }
    }
    
    var body: some View {
        NavigationView {
            VStack{
                List(viewModel.movies) { movie in
                    MovieRow(movie: movie)
                }
            }
            .navigationTitle("Now Playing")
            
        }.onAppear {
            if !self.loading{
                viewModel.fetchNowPlayingMovies()
            }
        }
    }
}

@available(iOS 15, macOS 10.15, *)
#Preview {
    DMSNowPlayingView()
}
