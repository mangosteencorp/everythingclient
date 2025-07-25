import SwiftUI
import Swinject
import TMDB_Shared_Backend
@available(iOS 16, *)
public struct HomeDiscoverView<Route: Hashable>: View {
    @StateObject var viewModel: HomeDiscoverViewModel
    let detailRouteBuilder: (Int) -> Route
    let onItemTapped: () -> Void

    public init(
        container: Container,
        apiKey: String,
        detailRouteBuilder: @escaping (Int) -> Route,
        onItemTapped: @escaping () -> Void = {}
    ) {
        APIKeys.tmdbKey = apiKey
        let movieAssembly = DiscoverAssembly()
        movieAssembly.assemble(container: container)
        self.detailRouteBuilder = detailRouteBuilder
        self.onItemTapped = onItemTapped

        _viewModel = StateObject(wrappedValue: HomeDiscoverViewModel(
            fetchGenresUseCase: DefaultFetchGenresUseCase(repository: MovieRepositoryImpl(apiService: container.resolve(TMDBAPIService.self)!)),
            fetchPopularPeopleUseCase: DefaultFetchPopularPeopleUseCase(repository: MovieRepositoryImpl(apiService: container.resolve(TMDBAPIService.self)!)),
            fetchTrendingItemsUseCase: DefaultFetchTrendingItemsUseCase(repository: MovieRepositoryImpl(apiService: container.resolve(TMDBAPIService.self)!)))
        )
    }

    public var body: some View {
        HomeDiscoverViewControllerRepresentable(viewModel: viewModel, onItemTapped: onItemTapped)
    }
}

@available(iOS 16, *)
struct HomeDiscoverViewControllerRepresentable: UIViewControllerRepresentable {
    let viewModel: HomeDiscoverViewModel
    let onItemTapped: () -> Void

    func makeUIViewController(context: Context) -> HomeDiscoverViewController {
        let viewController = HomeDiscoverViewController(viewModel: viewModel)
        viewController.onItemTapped = onItemTapped
        return viewController
    }

    func updateUIViewController(_ uiViewController: HomeDiscoverViewController, context: Context) {
        // Updates handled by the view model
    }
}
