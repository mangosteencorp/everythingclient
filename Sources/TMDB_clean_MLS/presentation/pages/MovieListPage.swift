import SwiftUI
import Swinject
import TMDB_Shared_UI
@available(iOS 16.0, *)
public struct MovieListPage<Route: Hashable>: View {
    @StateObject var viewModel: TVShowsViewModel
    let type: TVShowListType
    let detailRouteBuilder: (Int) -> Route
    public init(
        container: Container,
        apiKey: String,
        type: TVShowListType,
        detailRouteBuilder: @escaping (Int) -> Route
    ) {
        APIKeys.tmdbKey = apiKey
        let movieAssembly = TVShowAssembly()
        movieAssembly.assemble(container: container)
        self.detailRouteBuilder = detailRouteBuilder
        switch type {
        case .airingToday:
            _viewModel = StateObject(wrappedValue: container.resolve(TVShowsViewModel.self, name: "airingToday")!)
        case .onTheAir:
            _viewModel = StateObject(wrappedValue: container.resolve(TVShowsViewModel.self, name: "onTheAir")!)
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
                    MovieListContent(movies: viewModel.tvShows, detailRouteBuilder: detailRouteBuilder)
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
            viewModel.fetchTVShows()
        }
    }
}

public enum TVShowListType {
    case airingToday
    case onTheAir

    var title: String {
        switch self {
        case .airingToday:
            return "Airing Today"
        case .onTheAir:
            return "On The Air"
        }
    }

    var iconName: String {
        switch self {
        case .airingToday:
            return "play.circle"
        case .onTheAir:
            return "tv"
        }
    }
}

enum APIKeys {
    static var tmdbKey = ""
}
