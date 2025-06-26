import SwiftUI
import Swinject
import TMDB_Shared_UI
@available(iOS 16.0, *)
public struct TVShowListPage<Route: Hashable>: View {
    @StateObject var viewModel: TVFeedViewModel
    let type: TVShowFeedType
    let detailRouteBuilder: (Int) -> Route
    public init(
        container: Container,
        apiKey: String,
        type: TVShowFeedType,
        detailRouteBuilder: @escaping (Int) -> Route
    ) {
        APIKeys.tmdbKey = apiKey
        let movieAssembly = MovieAssembly()
        movieAssembly.assemble(container: container)
        self.detailRouteBuilder = detailRouteBuilder
        switch type {
        case .airingToday:
            _viewModel = StateObject(wrappedValue: container.resolve(TVFeedViewModel.self, name: "nowPlaying")!)
        case .onTheAir:
            _viewModel = StateObject(wrappedValue: container.resolve(TVFeedViewModel.self, name: "upcoming")!)
        }

        self.type = type
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .id("loadingView")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .id("errorView")
            } else {
                TVShowListContent(movies: viewModel.movies, detailRouteBuilder: detailRouteBuilder)
                    .id("movieListContent")
            }
        }
        .navigationTitle(type.title)
        .accessibilityIdentifier("movieListPage.group")
        .onFirstAppear {
            viewModel.fetchMovies()
        }
    }
}

enum APIKeys {
    static var tmdbKey = ""
}
