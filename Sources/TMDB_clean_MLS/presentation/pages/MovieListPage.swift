import SwiftUI
import Swinject

@available(iOS 16.0, *)
public struct MovieListPage: View {
    @StateObject private var viewModel: MoviesViewModel
    let type: MovieListType
    
    public init(container: Container, apiKey: String, type: MovieListType) {
        APIKeys.tmdbKey = apiKey
        let movieAssembly = MovieAssembly()
        movieAssembly.assemble(container: container)
        let viewModel: MoviesViewModel
        switch type {
        case .nowPlaying:
            viewModel = container.resolve(MoviesViewModel.self, name: "nowPlaying")!
        case .upcoming:
            viewModel = container.resolve(MoviesViewModel.self, name: "upcoming")!
        }
        _viewModel = StateObject(wrappedValue: viewModel)
        self.type = type
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                } else {
                    MovieListContent(movies: viewModel.movies)
                }
            }
            .navigationTitle(type.title)
            .onAppear {
                viewModel.fetchMovies()
            }
        }
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
    }
}
public enum MovieListType {
    case nowPlaying
    case upcoming
    
    var title: String {
        switch self {
        case .nowPlaying:
            return "Now Playing"
        case .upcoming:
            return "Upcoming"
        }
    }
    
    var iconName: String {
        switch self {
        case .nowPlaying:
            return "play.circle"
        case .upcoming:
            return "calendar"
        }
    }
}
struct APIKeys {
    static var tmdbKey = ""
}
