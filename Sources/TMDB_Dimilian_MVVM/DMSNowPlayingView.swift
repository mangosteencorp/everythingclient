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
public struct DMSNowPlayingView: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    public init(apiKey: String){
        APIKeys.tmdbKey = apiKey
    }
    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                } else {
                    List(viewModel.movies) { movie in
                        MovieRow(movie: movie)
                    }
                }
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchNowPlayingMovies()
            }
        }
    }
}

@available(iOS 15, macOS 10.15, *)
#Preview {
    DMSNowPlayingView(apiKey: <#T##String#>)
}
