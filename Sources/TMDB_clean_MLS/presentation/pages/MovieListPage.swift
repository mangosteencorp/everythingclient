import SwiftUI
import Swinject

@available(iOS 16.0, *)
public struct MovieListPage: View {
    @ObservedObject private(set) var viewModel: MoviesViewModel
    let type: MovieListType
    
    public init(container: Container, apiKey: String, type: MovieListType) {
        APIKeys.tmdbKey = apiKey
        let movieAssembly = MovieAssembly()
        movieAssembly.assemble(container: container)
        
        switch type {
        case .nowPlaying:
            self.viewModel = container.resolve(MoviesViewModel.self, name: "nowPlaying")!
        case .upcoming:
            self.viewModel = container.resolve(MoviesViewModel.self, name: "upcoming")!
        }
        
        self.type = type
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .id("loadingView")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .id("errorView")
                } else {
                    MovieListContent(movies: viewModel.movies)
                        .id("movieListContent")
                }
            }
            .navigationTitle(type.title)
            .onAppear {
                viewModel.fetchMovies()
            }
            .accessibilityIdentifier("movieListPage.group")
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
