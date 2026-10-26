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
        let movieAssembly = DiscoverAssembly(apiKey: apiKey)
        movieAssembly.assemble(container: container)
        self.detailRouteBuilder = detailRouteBuilder

        let discoverParams: DiscoverMoviesParams
        switch type {
        case let .discoverWithGenre(genre):
            // Use mediaType: .movie for movie genre filtering
            discoverParams = DiscoverMoviesParams(genres: [genre.id], mediaType: .movie)
        case let .discoverWithTVGenre(genre):
            // Use mediaType: .tv for TV genre filtering (TV genre IDs are different from movie genre IDs)
            discoverParams = DiscoverMoviesParams(genres: [genre.id], mediaType: .tv)
        }

        _viewModel = StateObject(
            wrappedValue: container.resolve(TVFeedViewModel.self, name: "discover", argument: discoverParams)!
        )
        self.type = type
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

#if DEBUG
#Preview("UIKit list") {
    TMDBDiscoverPreviewCatalog.listPage.view
}
#endif
