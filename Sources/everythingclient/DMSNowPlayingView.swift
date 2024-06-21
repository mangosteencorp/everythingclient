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
struct DMSNowPlayingView: View {
    @StateObject private var viewModel = NowPlayingViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    List(Array(repeating: sampleEmptyMovie, count: 20)){
                        MovieRow(movie: $0)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                } else {
                    List(viewModel.movies) { movie in
                        MovieRow(movie: movie)
                    }
                }
            }
            .navigationTitle("Now Playing")
            .onAppear {
                fetch()
            }
        }
    }
    func fetch() {
        viewModel.fetchNowPlayingMovies()
    }
}

// Create a UIViewController that hosts a SwiftUI view
@available(iOS 15, macOS 10.15, *)
class NowPlayingHostingController: UIHostingController<DMSNowPlayingView> {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: DMSNowPlayingView())
    }

    override init(rootView: DMSNowPlayingView) {
        super.init(rootView: rootView)
    }
    
}
@available(iOS 15, macOS 10.15, *)
struct NowPlayingViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NowPlayingHostingController {
        return NowPlayingHostingController(rootView: DMSNowPlayingView())
    }

    func updateUIViewController(_ uiViewController: NowPlayingHostingController, context: Context) {
        // Update the view controller if needed
    }
}

@available(iOS 15, macOS 10.15, *)
#Preview {
    DMSNowPlayingView()
}
@available(iOS 17, *)
#Preview {
    NowPlayingHostingController(rootView: DMSNowPlayingView())
}
