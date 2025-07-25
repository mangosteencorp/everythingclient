#if canImport(UIKit)
import UIKit
#endif
import Combine
import CoreFeatures
import Shared_UI_Support
import SnapKit
import TMDB_Shared_Backend

class TVShowListViewController: UIViewController, UISearchBarDelegate, FavButtonDelegate {
    // MARK: - Properties

    private let viewModel: TVFeedViewModel
    private var movies: [Movie] = []
    private var filteredMovies: [Movie] = []
    private var searchBar: UISearchBar!
    private var refreshControl: UIRefreshControl!
    private var collectionView: UICollectionView!
    private let padding: Int = 8
    private let searchBarHeight: Int = 60
    private var searchString: String?
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
        setupSearchBar()
        setupCollectionView()
        setupPullToRefresh()
        setupBindings()
        viewModel.fetchMovies()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "TV Shows"
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

    private func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.searchBarStyle = .prominent
        searchBar.tintColor = .white
        searchBar.barTintColor = .white
        searchBar.delegate = self
        searchBar.placeholder = "Filter..."
        searchBar.isTranslucent = true
        searchBar.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.75)
        searchBar.backgroundImage = UIImage()

        if #available(iOS 13.0, *) {
            searchBar.searchTextField.backgroundColor = .clear
        } else {
            if let textField = searchBar.value(forKey: "searchField") as? UITextField {
                textField.backgroundColor = .clear
            }
        }

        view.addSubview(searchBar)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(searchBarHeight)
        }
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = CGFloat(padding)
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MovieItemCell.self, forCellWithReuseIdentifier: "MovieItemCell")

        let top = CGFloat(searchBarHeight + padding)
        collectionView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)

        view.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.addSubview(refreshControl)
    }

    @objc private func handleRefresh() {
        viewModel.fetchMovies()
    }

    private func setupBindings() {
        // Observe viewModel changes
        viewModel.$movies
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                self?.movies = movies
                self?.filteredMovies = movies
                self?.collectionView.reloadData()
                self?.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    // Handle error display if needed
                    print("Error: \(errorMessage)")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Search Bar Delegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            cancelSearching()
            view.endEditing(true)
        }
        searchString = searchText
        applyFilter()
        collectionView.reloadData()
        scrollToTop()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }

    private func applyFilter() {
        guard let searchString = searchString, !searchString.isEmpty else {
            filteredMovies = movies
            return
        }
        filteredMovies = movies.filter { movie in
            movie.title.lowercased().contains(searchString.lowercased()) ||
            movie.overview.lowercased().contains(searchString.lowercased())
        }
    }

    private func cancelSearching() {
        DispatchQueue.main.async {
            self.searchBar.resignFirstResponder()
            self.searchBar.text = ""
            self.searchString = nil
            self.filteredMovies = self.movies
            self.collectionView.reloadData()
        }
    }

    private func scrollToTop() {
        if !filteredMovies.isEmpty {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
        }
    }

    // MARK: - FavButtonDelegate

    func favButtonTapped(for item: ItemDisplayable) {
        guard let movie = item as? Movie else { return }

        Task {
            await viewModel.toggleFavorite(for: movie.id)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension TVShowListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredMovies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "MovieItemCell",
            for: indexPath
        ) as? MovieItemCell else {
            return UICollectionViewCell()
        }

        let movie = filteredMovies[indexPath.item]
        cell.delegate = self
        cell.configure(with: movie)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TVShowListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = Int(collectionView.bounds.size.width) - (padding * 2)
        let height = ThemeService.cellsHeight
        return CGSize(width: width, height: height)
    }
}

// MARK: - UICollectionViewDelegate

extension TVShowListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = filteredMovies[indexPath.item]
        // Handle movie selection - you can add navigation logic here
        print("Selected movie: \(movie.title)")
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Implement pagination if needed
        // if indexPath.item == filteredMovies.count - 1 {
        //     // Load more data
        // }
    }
}

#if DEBUG
@available(iOS 17, *)
#Preview {
    let viewModel = TVFeedViewModel(fetchMoviesUseCase: MockFetchMoviesUseCase())
    let nav = UINavigationController(rootViewController: TVShowListViewController(viewModel: viewModel))
    return nav
}

// MARK: - Mock Use Case for Preview

private class MockFetchMoviesUseCase: FetchMoviesUseCase {
    func execute() async -> Result<[Movie], Error> {
        return .success(Movie.exampleMovies)
    }
}
#endif
