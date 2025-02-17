import SwiftUI
import Swinject
import TMDB_Shared_UI
@available(iOS 16.0, *)
public struct MovieListPage<Route: Hashable>: View {
    @StateObject var viewModel: MoviesViewModel
    let type: MovieListType
    let detailRouteBuilder: (Int) -> Route
    public init(
        container: Container,
        apiKey: String,
        type: MovieListType,
        detailRouteBuilder: @escaping (Int) -> Route
    ) {
        APIKeys.tmdbKey = apiKey
        let movieAssembly = MovieAssembly()
        movieAssembly.assemble(container: container)
        self.detailRouteBuilder = detailRouteBuilder
        switch type {
        case .nowPlaying:
            _viewModel = StateObject(wrappedValue: container.resolve(MoviesViewModel.self, name: "nowPlaying")!)
        case .upcoming:
            _viewModel = StateObject(wrappedValue: container.resolve(MoviesViewModel.self, name: "upcoming")!)
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
                    MovieListContent(movies: viewModel.movies, detailRouteBuilder: detailRouteBuilder)
                        .id("movieListContent")
                }
            }
            .navigationTitle(type.title)
        }
#if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
#endif
        .accessibilityIdentifier("movieListPage.group")
        .onFirstAppear {
            viewModel.fetchMovies()
        }
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

enum APIKeys {
    static var tmdbKey = ""
}
