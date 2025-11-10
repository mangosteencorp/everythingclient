import SwiftUI
import Swinject
import TMDB_Shared_Backend
@available(iOS 16, *)
public struct HomeDiscoverView<Route: Hashable>: View {
    @StateObject var viewModel: HomeDiscoverViewModel
    let detailRouteBuilder: (Int) -> Route
    let onItemTapped: () -> Void
    let onGenreTapped: (Genre) -> Void
    let onTVGenreTapped: (Genre) -> Void
    let onCastTapped: (PopularPerson) -> Void
    let onTrendingItemTapped: (TrendingItem) -> Void

    public init(
        container: Container,
        apiKey: String,
        detailRouteBuilder: @escaping (Int) -> Route,
        onItemTapped: @escaping () -> Void = {},
        onGenreTapped: @escaping (Genre) -> Void = { _ in },
        onTVGenreTapped: @escaping (Genre) -> Void = { _ in },
        onCastTapped: @escaping (PopularPerson) -> Void = { _ in },
        onTrendingItemTapped: @escaping (TrendingItem) -> Void = { _ in }
    ) {
        APIKeys.tmdbKey = apiKey
        let movieAssembly = DiscoverAssembly()
        movieAssembly.assemble(container: container)
        self.detailRouteBuilder = detailRouteBuilder
        self.onItemTapped = onItemTapped
        self.onGenreTapped = onGenreTapped
        self.onTVGenreTapped = onTVGenreTapped
        self.onCastTapped = onCastTapped
        self.onTrendingItemTapped = onTrendingItemTapped

        let repository = MovieRepositoryImpl(apiService: container.resolve(TMDBAPIService.self)!)
        _viewModel = StateObject(wrappedValue: HomeDiscoverViewModel(
            fetchGenresUseCase: DefaultFetchGenresUseCase(repository: repository),
            fetchTVGenresUseCase: DefaultFetchTVGenresUseCase(repository: repository),
            fetchPopularPeopleUseCase: DefaultFetchPopularPeopleUseCase(repository: repository),
            fetchTrendingItemsUseCase: DefaultFetchTrendingItemsUseCase(repository: repository))
        )
    }

    public var body: some View {
        HomeDiscoverViewControllerRepresentable(
            viewModel: viewModel,
            onItemTapped: onItemTapped,
            onGenreTapped: onGenreTapped,
            onTVGenreTapped: onTVGenreTapped,
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
    let onTVGenreTapped: (Genre) -> Void
    let onCastTapped: (PopularPerson) -> Void
    let onTrendingItemTapped: (TrendingItem) -> Void

    func makeUIViewController(context: Context) -> HomeDiscoverViewController {
        let viewController = HomeDiscoverViewController(viewModel: viewModel)
        viewController.onItemTapped = onItemTapped
        viewController.onGenreTapped = onGenreTapped
        viewController.onTVGenreTapped = onTVGenreTapped
        viewController.onCastTapped = onCastTapped
        viewController.onTrendingItemTapped = onTrendingItemTapped
        return viewController
    }

    func updateUIViewController(_ uiViewController: HomeDiscoverViewController, context: Context) {
        // Updates handled by the view model
    }
}
