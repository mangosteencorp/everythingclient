// This whole target is UIKit-only and is reachable from iOS builds alone (see
// `Package.swift`). The guard keeps it compiling to an empty module if a toolchain or
// IDE builds every target regardless of reachability, rather than failing on `import UIKit`.
#if canImport(UIKit)
import SnapKit
import UIKit

public protocol FilterableFavouritableItemListDelegate: AnyObject {
    func filterableList(_ list: FilterableFavouritableItemList, didUpdateQuery query: String?)
    func filterableListDidRequestRefresh(_ list: FilterableFavouritableItemList)
    func filterableList(_ list: FilterableFavouritableItemList, didSelect item: ItemDisplayable)
    func filterableList(_ list: FilterableFavouritableItemList, didTapFavoriteFor item: ItemDisplayable)
}

public extension FilterableFavouritableItemListDelegate {
    func filterableList(_ list: FilterableFavouritableItemList, didUpdateQuery query: String?) {}
    func filterableListDidRequestRefresh(_ list: FilterableFavouritableItemList) {}
    func filterableList(_ list: FilterableFavouritableItemList, didSelect item: ItemDisplayable) {}
    func filterableList(_ list: FilterableFavouritableItemList, didTapFavoriteFor item: ItemDisplayable) {}
}

public final class FilterableFavouritableItemList: UIViewController {
    // MARK: - Public API

    public weak var delegate: FilterableFavouritableItemListDelegate?

    public var searchPlaceholder: String? {
        didSet {
            searchBar.placeholder = searchPlaceholder
        }
    }

    public var showsRefreshControl: Bool = true {
        didSet {
            updateRefreshControlVisibility()
        }
    }

    public func display(items: [ItemDisplayable], scrollToTop: Bool = false) {
        self.items = items
        collectionView.reloadData()
        if scrollToTop, !items.isEmpty {
            let indexPath = IndexPath(item: 0, section: 0)
            collectionView.layoutIfNeeded()
            collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        }
        refreshControl.endRefreshing()
    }

    public func endRefreshing() {
        refreshControl.endRefreshing()
    }

    public func beginRefreshing() {
        if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
        }
    }

    // MARK: - Private Properties

    private let padding: CGFloat = 8
    private let searchBarHeight: CGFloat = 60
    private var items: [ItemDisplayable] = []

    private let searchBar: UISearchBar = UISearchBar()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = padding
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(MovieItemCell.self, forCellWithReuseIdentifier: MovieItemCell.reuseIdentifier)
        return collectionView
    }()

    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = ThemeService.lightGrey
        setupSearchBar()
        setupCollectionView()
        setupRefreshControl()
        updateRefreshControlVisibility()
    }

    private func setupSearchBar() {
        searchBar.searchBarStyle = .prominent
        searchBar.tintColor = .white
        searchBar.barTintColor = .white
        searchBar.delegate = self
        searchBar.placeholder = searchPlaceholder ?? "Filter..."
        searchBar.isTranslucent = true
        searchBar.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.75)
        searchBar.backgroundImage = UIImage()

        if #available(iOS 13.0, *) {
            searchBar.searchTextField.backgroundColor = .clear
        } else if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .clear
        }

        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(searchBarHeight)
        }
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }

    private func updateRefreshControlVisibility() {
        guard isViewLoaded else { return }
        if showsRefreshControl {
            if #available(iOS 10.0, *) {
                collectionView.refreshControl = refreshControl
            } else if refreshControl.superview == nil {
                collectionView.addSubview(refreshControl)
            }
        } else {
            if #available(iOS 10.0, *) {
                collectionView.refreshControl = nil
            } else {
                refreshControl.removeFromSuperview()
            }
        }
    }

    @objc private func handleRefresh() {
        delegate?.filterableListDidRequestRefresh(self)
    }
}

// MARK: - UICollectionViewDataSource

extension FilterableFavouritableItemList: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MovieItemCell.reuseIdentifier,
            for: indexPath
        ) as? MovieItemCell else {
            return UICollectionViewCell()
        }

        let item = items[indexPath.item]
        cell.delegate = self
        cell.configure(with: item)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FilterableFavouritableItemList: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = Int(collectionView.bounds.size.width) - (Int(padding) * 2)
        let height = ThemeService.cellsHeight
        return CGSize(width: width, height: height)
    }
}

// MARK: - UICollectionViewDelegate

extension FilterableFavouritableItemList: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        delegate?.filterableList(self, didSelect: item)
    }
}

// MARK: - UISearchBarDelegate

extension FilterableFavouritableItemList: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let sanitizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = sanitizedQuery.isEmpty ? nil : sanitizedQuery
        delegate?.filterableList(self, didUpdateQuery: query)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - FavButtonDelegate

extension FilterableFavouritableItemList: FavButtonDelegate {
    public func favButtonTapped(for item: ItemDisplayable) {
        delegate?.filterableList(self, didTapFavoriteFor: item)
    }
}

private extension MovieItemCell {
    static var reuseIdentifier: String {
        "MovieItemCell"
    }
}
#endif
