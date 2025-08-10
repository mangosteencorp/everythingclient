import CoreFeatures
import SwiftUI
import Swinject
import TMDB_Shared_UI

@available(iOS 16.0, *)
public struct TVShowListPage<Route: Hashable>: View {
    @StateObject var viewModel: TVFeedViewModel
    @State private var useUIKitView = false
    let type: TVShowFeedType
    let detailRouteBuilder: (Int) -> Route

    public init(
        container: Container,
        apiKey: String,
        type: TVShowFeedType,
        detailRouteBuilder: @escaping (Int) -> Route
    ) {
        APIKeys.tmdbKey = apiKey
        let movieAssembly = DiscoverAssembly()
        movieAssembly.assemble(container: container)
        self.detailRouteBuilder = detailRouteBuilder
        
        // Create discover parameters if we have genre information
        var discoverParams: DiscoverMoviesParams?
        if case .discoverWithGenre(let genre) = type {
            discoverParams = DiscoverMoviesParams(genres: [genre.id])
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
        case .discoverWithGenre:
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
            if useUIKitView {
                TVShowListViewControllerRepresentable(viewModel: viewModel)
            } else {
                TVShowListPageContent(
                    viewModel: viewModel,
                    type: type,
                    detailRouteBuilder: detailRouteBuilder
                )
            }
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

enum APIKeys {
    static var tmdbKey = ""
}
