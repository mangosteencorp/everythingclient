import SwiftUI
import Swinject
import TMDB_Shared_Backend
@available(iOS 16, *)
public struct HomeDiscoverView<Route: Hashable>: View {
    @StateObject var viewModel: HomeDiscoverViewModel
    let detailRouteBuilder: (Int) -> Route
    let onItemTapped: () -> Void
    let onGenreTapped: (Genre) -> Void
    let onCastTapped: (PopularPerson) -> Void
    let onTrendingItemTapped: (TrendingItem) -> Void

    public init(
        container: Container,
        apiKey: String,
        detailRouteBuilder: @escaping (Int) -> Route,
        onItemTapped: @escaping () -> Void = {},
        onGenreTapped: @escaping (Genre) -> Void = { _ in },
        onCastTapped: @escaping (PopularPerson) -> Void = { _ in },
        onTrendingItemTapped: @escaping (TrendingItem) -> Void = { _ in }
    ) {
        APIKeys.tmdbKey = apiKey
        let movieAssembly = DiscoverAssembly()
        movieAssembly.assemble(container: container)
        self.detailRouteBuilder = detailRouteBuilder
        self.onItemTapped = onItemTapped
        self.onGenreTapped = onGenreTapped
        self.onCastTapped = onCastTapped
        self.onTrendingItemTapped = onTrendingItemTapped

        _viewModel = StateObject(wrappedValue: HomeDiscoverViewModel(
            fetchGenresUseCase: DefaultFetchGenresUseCase(repository: MovieRepositoryImpl(apiService: container.resolve(TMDBAPIService.self)!)),
            fetchPopularPeopleUseCase: DefaultFetchPopularPeopleUseCase(repository: MovieRepositoryImpl(apiService: container.resolve(TMDBAPIService.self)!)),
            fetchTrendingItemsUseCase: DefaultFetchTrendingItemsUseCase(repository: MovieRepositoryImpl(apiService: container.resolve(TMDBAPIService.self)!)))
        )
    }

    public var body: some View {
        HomeDiscoverViewControllerRepresentable(
            viewModel: viewModel,
            onItemTapped: onItemTapped,
            onGenreTapped: onGenreTapped,
            onCastTapped: onCastTapped,
            onTrendingItemTapped: onTrendingItemTapped
        )
    }
}

@available(iOS 16, *)
struct HomeDiscoverViewControllerRepresentable: UIViewControllerRepresentable {
    let viewModel: HomeDiscoverViewModel
    let onItemTapped: () -> Void
    let onGenreTapped: (Genre) -> Void
    let onCastTapped: (PopularPerson) -> Void
    let onTrendingItemTapped: (TrendingItem) -> Void

    func makeUIViewController(context: Context) -> HomeDiscoverViewController {
        let viewController = HomeDiscoverViewController(viewModel: viewModel)
        viewController.onItemTapped = onItemTapped
        viewController.onGenreTapped = onGenreTapped
        viewController.onCastTapped = onCastTapped
        viewController.onTrendingItemTapped = onTrendingItemTapped
        return viewController
    }

    func updateUIViewController(_ uiViewController: HomeDiscoverViewController, context: Context) {
        // Updates handled by the view model
    }
}
