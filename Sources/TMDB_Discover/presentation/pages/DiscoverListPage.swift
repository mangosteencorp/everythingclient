import CoreFeatures
import SwiftUI
import Swinject
import TMDB_Shared_UI

@available(iOS 16.0, *)
public struct DiscoverListPage<Route: Hashable>: View {
    @StateObject var viewModel: TVFeedViewModel
    @State private var useUIKitView = false
    let type: TVShowFeedType
    let detailRouteBuilder: (Int, DiscoverMediaType) -> Route

    public init(
        container: Container,
        apiKey: String,
        type: TVShowFeedType,
        detailRouteBuilder: @escaping (Int, DiscoverMediaType) -> Route
    ) {
        APIKeys.tmdbKey = apiKey
        let movieAssembly = DiscoverAssembly()
        movieAssembly.assemble(container: container)
        self.detailRouteBuilder = detailRouteBuilder

        // Create discover parameters if we have genre information
        var discoverParams: DiscoverMoviesParams?
        if case .discoverWithGenre(let genre) = type {
            // Use mediaType: .movie for movie genre filtering
            discoverParams = DiscoverMoviesParams(genres: [genre.id], mediaType: .movie)
        } else if case .discoverWithTVGenre(let genre) = type {
            // Use mediaType: .tv for TV genre filtering (TV genre IDs are different from movie genre IDs)
            discoverParams = DiscoverMoviesParams(genres: [genre.id], mediaType: .tv)
        } else if case .discoverWithCast(let person) = type {
            // Use mediaType: .movie for cast filtering (assuming movies by default)
            discoverParams = DiscoverMoviesParams(cast: person.id, mediaType: .movie)
        }

        switch type {
        case .airingToday:
            _viewModel = StateObject(wrappedValue: container.resolve(TVFeedViewModel.self, name: "nowPlaying")!)
        case .onTheAir:
            _viewModel = StateObject(wrappedValue: container.resolve(TVFeedViewModel.self, name: "upcoming")!)
        case .discover:
            if let params = discoverParams {
                _viewModel = StateObject(wrappedValue: container.resolve(TVFeedViewModel.self, name: "discover", argument: params)!)
            } else {
                _viewModel = StateObject(wrappedValue: container.resolve(TVFeedViewModel.self, name: "discover")!)
            }
        case .discoverWithGenre, .discoverWithTVGenre, .discoverWithCast:
            if let params = discoverParams {
                _viewModel = StateObject(wrappedValue: container.resolve(TVFeedViewModel.self, name: "discover", argument: params)!)
            } else {
                _viewModel = StateObject(wrappedValue: container.resolve(TVFeedViewModel.self, name: "discover")!)
            }
        }

        self.type = type

        // If we resolved the VM without params for some reason, still set afterwards
        if let params = discoverParams {
            viewModel.setDiscoverParams(params)
        }
    }

    public var body: some View {
        Group {
#if canImport(UIKit)
            if useUIKitView {
                TVShowListViewControllerRepresentable(viewModel: viewModel)
            } else {
                TVShowListPageContent(
                    viewModel: viewModel,
                    type: type,
                    detailRouteBuilder: detailRouteBuilder
                )
            }
            #else
            TVShowListPageContent(
                viewModel: viewModel,
                type: type,
                detailRouteBuilder: detailRouteBuilder
            )
            #endif
        }
        .navigationTitle(type.title)
        .accessibilityIdentifier("movieListPage.group")
        .toolbar {
            SwitchDesignToolbarItem {
                useUIKitView.toggle()
            }
        }
    }
}
#if canImport(UIKit)
@available(iOS 16.0, *)
struct TVShowListViewControllerRepresentable: UIViewControllerRepresentable {
    let viewModel: TVFeedViewModel

    func makeUIViewController(context: Context) -> TVShowListViewController {
        return TVShowListViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: TVShowListViewController, context: Context) {
        // Updates handled by the view model
    }
}
#endif
enum APIKeys {
    static var tmdbKey = ""
}
