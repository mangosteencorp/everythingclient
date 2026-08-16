#if canImport(UIKit)
import UIKit
#endif
import Combine
import CoreFeatures
import Shared_UI_Support
import SnapKit
import TMDB_Shared_Backend

class TVShowListViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: TVFeedViewModel
    private var movies: [Movie] = []
    private var filteredMovies: [Movie] = []
    private var searchString: String?
    private let filterableList = FilterableFavouritableItemList()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(viewModel: TVFeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupFilterableList()
        setupBindings()
        viewModel.fetchMovies()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "TV Shows"
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only when leaving for good: plain `viewWillDisappear` also fires when another controller
        // is pushed on top, and the list should keep loading in that case.
        if isMovingFromParent || isBeingDismissed {
            viewModel.cancelLoad()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.hidesBarsOnSwipe = true
        navigationController?.navigationBar.tintColor = ThemeService.black
        navigationController?.navigationBar.titleTextAttributes = nil
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = ThemeService.lightGrey
    }

    private func setupFilterableList() {
        addChild(filterableList)
        filterableList.loadViewIfNeeded()
        view.addSubview(filterableList.view)

        filterableList.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        filterableList.didMove(toParent: self)
        filterableList.delegate = self
        filterableList.searchPlaceholder = "Filter..."
    }

    private func setupBindings() {
        // Observe viewModel changes
        viewModel.$movies
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                self?.movies = movies
                // Apply current filter when new movies arrive
                self?.applyFilter(scrollToTop: false)
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.filterableList.endRefreshing()
                }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { errorMessage in
                if let errorMessage = errorMessage {
                    // Handle error display if needed
                    print("Error: \(errorMessage)")
                }
            }
            .store(in: &cancellables)
    }

    private func applyFilter(scrollToTop: Bool) {
        guard let searchString = searchString, !searchString.isEmpty else {
            filteredMovies = movies
            filterableList.display(items: filteredMovies.map { $0 as ItemDisplayable }, scrollToTop: scrollToTop)
            return
        }
        let lowercasedSearch = searchString.lowercased()
        filteredMovies = movies.filter { movie in
            movie.title.lowercased().contains(lowercasedSearch) ||
            movie.overview.lowercased().contains(lowercasedSearch)
        }
        filterableList.display(items: filteredMovies.map { $0 as ItemDisplayable }, scrollToTop: scrollToTop)
    }
}

// MARK: - FilterableFavouritableItemListDelegate

extension TVShowListViewController: FilterableFavouritableItemListDelegate {
    func filterableList(_ list: FilterableFavouritableItemList, didUpdateQuery query: String?) {
        searchString = query
        applyFilter(scrollToTop: true)
    }

    func filterableListDidRequestRefresh(_ list: FilterableFavouritableItemList) {
        viewModel.fetchMovies()
    }

    func filterableList(_ list: FilterableFavouritableItemList, didSelect item: ItemDisplayable) {
        guard let movie = item as? Movie else { return }
        // Handle movie selection - you can add navigation logic here
        print("Selected movie: \(movie.title)")
    }

    func filterableList(_ list: FilterableFavouritableItemList, didTapFavoriteFor item: ItemDisplayable) {
        guard let movie = item as? Movie else { return }
        Task {
            await viewModel.toggleFavorite(for: movie.id)
        }
    }
}

#if DEBUG
@available(iOS 17, *)
#Preview {
    let viewModel = TVFeedViewModel(
        fetchMoviesUseCase: MockFetchMoviesUseCase(),
        fetchFavoriteTVShowsUseCase: MockFetchFavoriteTVShowsUseCase()
    )
    let nav = UINavigationController(rootViewController: TVShowListViewController(viewModel: viewModel))
    return nav
}

// MARK: - Mock Use Cases for Preview

private class MockFetchMoviesUseCase: FetchMoviesUseCase {
    func execute() async -> Result<[Movie], Error> {
        return .success(Movie.exampleMovies)
    }
}

private class MockFetchFavoriteTVShowsUseCase: FetchFavoriteTVShowsUseCase {
    func execute() async -> Result<[Int], Error> {
        // Mock some favorites (first 2 movies)
        return .success([889_737, 1_100_782])
    }
}
#endif
