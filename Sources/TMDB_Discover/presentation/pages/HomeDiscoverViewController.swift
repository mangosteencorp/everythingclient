
import Combine
import Kingfisher
import TMDB_Shared_Backend
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
public typealias UIViewController = NSViewController
public typealias UIColor = NSColor
public typealias UIImage = NSImage
public typealias UIImageView = NSImageView
public typealias UILabel = NSTextField
public typealias UIFont = NSFont
public typealias UIView = NSView

#endif
// MARK: - Section Layout Configuration

public struct SectionLayout {
    public enum SectionType {
        case banner
        case categories
        case popularCategories
        case favourites
    }

    public let type: SectionType
    public let height: CGFloat
    public let data: [Any]
    public let headerTitle: String?
    public let isVisible: Bool
    public let onItemTapped: (Int) -> Void

    public init(type: SectionType, height: CGFloat, data: [Any], headerTitle: String? = nil, isVisible: Bool = true, onItemTapped: @escaping ((Int) -> Void)) {
        self.type = type
        self.height = height
        self.data = data
        self.headerTitle = headerTitle
        self.isVisible = isVisible
        self.onItemTapped = onItemTapped
    }
}

// MARK: - Data Models

fileprivate enum ImageSource {
    case sfSymbolName(String)
    case assetName(String)
    case imageUrl(URL)
}

fileprivate struct PillShapeItem {
    let name: String
    let imageSource: ImageSource
    let selection: (() -> Void)?
}

fileprivate struct CircleItem {
    let name: String
    let imageSource: ImageSource
}

fileprivate struct FavouriteListing {
    let imageSource: ImageSource
    let price: String
    let title: String
}

#if canImport(UIKit)

fileprivate extension UIImageView {
    func setImage(from source: ImageSource) {
        switch source {
        case .sfSymbolName(let name):
            image = UIImage(systemName: name)
        case .assetName(let name):
            image = UIImage(named: name)
        case .imageUrl(let url):
            kf.setImage(with: url)
        }
    }
}

// MARK: - Cell Classes

fileprivate class BannerCell: UICollectionViewCell {
    static let reuseIdentifier: String = "BannerCell"

    let iconImageView = UIImageView()
    let mainLabel = UILabel()
    let subLabel = UILabel()
    let closeButton = UIButton(type: .system)
    var onCloseTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0)

        iconImageView.image = UIImage(named: "photo")
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit

        mainLabel.text = "Quick post with AI"
        mainLabel.textColor = .white
        mainLabel.font = .boldSystemFont(ofSize: 16)

        subLabel.text = "List your items for sale in a jiffy"
        subLabel.textColor = .white
        subLabel.font = .systemFont(ofSize: 14)

        closeButton.setTitle("X", for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        contentView.addSubview(iconImageView)
        contentView.addSubview(mainLabel)
        contentView.addSubview(subLabel)
        contentView.addSubview(closeButton)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            mainLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            mainLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            subLabel.leadingAnchor.constraint(equalTo: mainLabel.leadingAnchor),
            subLabel.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 5),
            subLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            closeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    @objc private func closeTapped() {
        onCloseTapped?()
    }
}

fileprivate class PillShapeItemCell: UICollectionViewCell {
    static let reuseIdentifier: String = "PillShapeItemCell"

    let iconImageView = UIImageView()
    let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0)
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true

        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit

        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)

        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 5),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -10),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    func configure(with item: PillShapeItem) {
        iconImageView.setImage(from: item.imageSource)
        nameLabel.text = item.name
    }
}

fileprivate class CircleItemCell: UICollectionViewCell {
    static let reuseIdentifier: String = "CircleItemCell"

    let imageView = UIImageView()
    let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        imageView.tintColor = .white

        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.numberOfLines = 2
        nameLabel.textAlignment = .center

        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),

            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
        ])
    }

    func configure(with item: CircleItem) {
        imageView.setImage(from: item.imageSource)
        nameLabel.text = item.name
    }
}

fileprivate class FavouriteListingCell: UICollectionViewCell {
    static let reuseIdentifier: String = "FavouriteListingCell"

    let imageView = UIImageView()
    let priceLabel = UILabel()
    let titleLabel = UILabel()
    let heartIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true

        heartIcon.image = UIImage(systemName: "heart")
        heartIcon.tintColor = .white
        heartIcon.contentMode = .scaleAspectFit

        priceLabel.textColor = .white
        priceLabel.font = .boldSystemFont(ofSize: 14)

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 12)

        contentView.addSubview(imageView)
        contentView.addSubview(priceLabel)
        contentView.addSubview(titleLabel)
        imageView.addSubview(heartIcon)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        heartIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 100),

            heartIcon.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 5),
            heartIcon.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -5),
            heartIcon.widthAnchor.constraint(equalToConstant: 20),
            heartIcon.heightAnchor.constraint(equalToConstant: 20),

            priceLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),

            titleLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    func configure(with listing: FavouriteListing) {
        imageView.setImage(from: listing.imageSource)
        priceLabel.text = listing.price
        titleLabel.text = listing.title
    }
}

fileprivate class SectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier: String = "SectionHeader"

    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 18)

        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

// MARK: - Main View Controller

public class HomeDiscoverViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: - Properties

    private var sectionLayouts: [SectionLayout] = []
    private var viewModel: HomeDiscoverViewModel?
    private var cancellables = Set<AnyCancellable>()

    // Navigation closure
    public var onItemTapped: (() -> Void)?
    public var onGenreTapped: ((Genre) -> Void)?
    public var onTVGenreTapped: ((Genre) -> Void)?
    public var onCastTapped: ((PopularPerson) -> Void)?
    public var onTrendingItemTapped: ((TrendingItem) -> Void)?

    lazy var collectionView: UICollectionView = {
        let layout = createCompositionalLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    // MARK: - Initialization

    public init(viewModel: HomeDiscoverViewModel? = nil) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupDefaultSectionLayouts()
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupDefaultSectionLayouts()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDefaultSectionLayouts()
    }

    // MARK: - Public Methods

    public func configure(with sectionLayouts: [SectionLayout]) {
        self.sectionLayouts = sectionLayouts
        collectionView.reloadData()
    }

    public func updateSectionVisibility(at index: Int, isVisible: Bool) {
        guard index < sectionLayouts.count else { return }
        let existingLayout = sectionLayouts[index]
        sectionLayouts[index] = SectionLayout(
            type: existingLayout.type,
            height: existingLayout.height,
            data: existingLayout.data,
            headerTitle: existingLayout.headerTitle,
            isVisible: isVisible,
            onItemTapped: existingLayout.onItemTapped
        )
        collectionView.reloadData()
    }

    // MARK: - Private Methods

    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ -> NSCollectionLayoutSection? in
            guard let self = self, sectionIndex < self.sectionLayouts.count else { return nil }

            let sectionLayout = self.sectionLayouts[sectionIndex]

            switch sectionLayout.type {
            case .banner:
                // Banner section - full width
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(sectionLayout.height))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(sectionLayout.height))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15)
                return section

            case .categories:
                // Categories section - horizontal scrolling pills
                let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(120), heightDimension: .absolute(40))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(120), heightDimension: .absolute(40))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.interItemSpacing = .fixed(10)

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15)

                // Add header if needed
                if let headerTitle = sectionLayout.headerTitle {
                    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(30))
                    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                    section.boundarySupplementaryItems = [header]
                }

                return section

            case .popularCategories:
                // Popular categories section - horizontal scrolling circles
                let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(100), heightDimension: .absolute(120))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(100), heightDimension: .absolute(120))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.interItemSpacing = .fixed(15)

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15)

                // Add header if needed
                if let headerTitle = sectionLayout.headerTitle {
                    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(30))
                    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                    section.boundarySupplementaryItems = [header]
                }

                return section

            case .favourites:
                // Favourites section - horizontal scrolling items
                let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(150), heightDimension: .absolute(160))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(150), heightDimension: .absolute(160))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.interItemSpacing = .fixed(15)

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15)

                // Add header if needed
                if let headerTitle = sectionLayout.headerTitle {
                    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(30))
                    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                    section.boundarySupplementaryItems = [header]
                }

                return section
            }
        }
    }

    private func setupDefaultSectionLayouts() {
        let movieGenreItems = mapGenresToPillShapeItems()
        let tvGenreItems = mapTVGenresToPillShapeItems()

        sectionLayouts = [
            SectionLayout(
                type: .categories,
                height: 50,
                data: movieGenreItems,
                headerTitle: "Movie Genres",
                onItemTapped: { index in
                    guard movieGenreItems.indices.contains(index) else { return }
                    movieGenreItems[index].selection?()
                }
            ),
            SectionLayout(
                type: .categories,
                height: 50,
                data: tvGenreItems,
                headerTitle: "TV Genres",
                onItemTapped: { index in
                    guard tvGenreItems.indices.contains(index) else { return }
                    tvGenreItems[index].selection?()
                }
            ),
            SectionLayout(
                type: .popularCategories,
                height: 140,
                data: mapPopularPeopleToCircleItems(),
                headerTitle: "Popular People",
                onItemTapped: { index in
                    if let vm = self.viewModel, vm.popularPeople.indices.contains(index) {
                        let person = vm.popularPeople[index]
                        self.onCastTapped?(person)
                    }
                }
            ),
            SectionLayout(
                type: .favourites,
                height: 180,
                data: mapTrendingToFavouriteListings(),
                headerTitle: "Trending",
                onItemTapped: { index in
                    if let vm = self.viewModel, vm.trendingItems.indices.contains(index) {
                        let trendingItem = vm.trendingItems[index]
                        self.onTrendingItemTapped?(trendingItem)
                    }
                }
            ),
        ]
    }

    private func mapGenresToPillShapeItems() -> [PillShapeItem] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.genres.map { genre in
            PillShapeItem(
                name: genre.name,
                imageSource: .sfSymbolName("tag"),
                selection: { [weak self] in
                    self?.onGenreTapped?(genre)
                }
            )
        }
    }

    private func mapTVGenresToPillShapeItems() -> [PillShapeItem] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.tvGenres.map { genre in
            PillShapeItem(
                name: genre.name,
                imageSource: .sfSymbolName("tv"),
                selection: { [weak self] in
                    self?.onTVGenreTapped?(genre)
                }
            )
        }
    }

    private func mapPopularPeopleToCircleItems() -> [CircleItem] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.popularPeople.map { person in
            CircleItem(
                name: person.name,
                imageSource: person.profilePath != nil
                    ? .imageUrl(TMDBImageSize.profileMedium.buildImageUrl(path: person.profilePath!)!)
                    : .sfSymbolName("person.circle")
            )
        }
    }

    private func mapTrendingToFavouriteListings() -> [FavouriteListing] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.trendingItems.map { item in
            FavouriteListing(
                imageSource: item.posterPath != nil
                    ? .imageUrl(TMDBImageSize.backdropSmall.buildImageUrl(path: item.posterPath!)!)
                    : .sfSymbolName("photo"),
                price: "\(item.mediaType.rawValue.capitalized)",
                title: item.displayTitle
            )
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.reuseIdentifier)
        collectionView.register(PillShapeItemCell.self, forCellWithReuseIdentifier: PillShapeItemCell.reuseIdentifier)
        collectionView.register(CircleItemCell.self, forCellWithReuseIdentifier: CircleItemCell.reuseIdentifier)
        collectionView.register(FavouriteListingCell.self, forCellWithReuseIdentifier: FavouriteListingCell.reuseIdentifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.reuseIdentifier)

        setupBindings()
        fetchDataIfNeeded()
    }

    private func setupBindings() {
        guard let viewModel = viewModel else { return }

        viewModel.$genres
            .combineLatest(viewModel.$tvGenres, viewModel.$popularPeople, viewModel.$trendingItems)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _, _ in
                self?.updateSectionLayouts()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.handleLoadingState(isLoading)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }

    private func fetchDataIfNeeded() {
        guard let viewModel = viewModel else { return }
        viewModel.fetchAllData()
    }

    private func updateSectionLayouts() {
        setupDefaultSectionLayouts()
        collectionView.reloadData()
    }

    private func handleLoadingState(_ isLoading: Bool) {
        // You can add loading indicator here
        // For now, just update UI interaction
        collectionView.isUserInteractionEnabled = !isLoading
    }

    private func handleError(_ errorMessage: String) {
        let alert = UIAlertController(
            title: "Error",
            message: errorMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionLayouts.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let layout = sectionLayouts[section]
        return layout.isVisible ? layout.data.count : 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let layout = sectionLayouts[indexPath.section]

        switch layout.type {
        case .banner:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.reuseIdentifier, for: indexPath) as? BannerCell else {
                return UICollectionViewCell()
            }
            cell.onCloseTapped = { [weak self] in
                self?.updateSectionVisibility(at: indexPath.section, isVisible: false)
            }
            return cell

        case .categories:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PillShapeItemCell.reuseIdentifier, for: indexPath) as? PillShapeItemCell,
                  let item = layout.data[indexPath.row] as? PillShapeItem else {
                return UICollectionViewCell()
            }
            cell.configure(with: item)
            return cell

        case .popularCategories:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CircleItemCell.reuseIdentifier, for: indexPath) as? CircleItemCell,
                  let item = layout.data[indexPath.row] as? CircleItem else {
                return UICollectionViewCell()
            }
            cell.configure(with: item)
            return cell

        case .favourites:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavouriteListingCell.reuseIdentifier, for: indexPath) as? FavouriteListingCell,
                  let listing = layout.data[indexPath.row] as? FavouriteListing else {
                return UICollectionViewCell()
            }
            cell.configure(with: listing)
            return cell
        }
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let layout = sectionLayouts[indexPath.section]
            if let headerTitle = layout.headerTitle {
                guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.reuseIdentifier, for: indexPath) as? SectionHeaderView else {
                    return UICollectionReusableView()
                }
                header.titleLabel.text = headerTitle
                return header
            }
        }
        return UICollectionReusableView()
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row

        guard section < sectionLayouts.count else { return }

        let sectionLayout = sectionLayouts[section]

        if sectionLayout.type == .categories,
           let items = sectionLayout.data as? [PillShapeItem],
           items.indices.contains(row) {
            items[row].selection?()
            return
        }

        // Use the section-specific callback defined in setupDefaultSectionLayouts
        // This properly handles multiple sections of the same type (e.g., Movie Genres and TV Genres)
        sectionLayout.onItemTapped(row)
    }
}

#if DEBUG
fileprivate let exampleMovieRespository = MovieRepositoryImpl(apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))
/// Grok: https://grok.com/chat/a4c29db6-3c12-4221-b134-490e4015d4d4
@available(iOS 17, *)
#Preview {
    HomeDiscoverViewController(
        viewModel:
            HomeDiscoverViewModel(
                fetchGenresUseCase:
                    DefaultFetchGenresUseCase(repository: exampleMovieRespository),
                fetchTVGenresUseCase:
                    DefaultFetchTVGenresUseCase(repository: exampleMovieRespository),
                fetchPopularPeopleUseCase: DefaultFetchPopularPeopleUseCase(repository: exampleMovieRespository),
                fetchTrendingItemsUseCase: DefaultFetchTrendingItemsUseCase(repository: exampleMovieRespository)))
}
#endif

/******************** AppKit Variant ********************/

#elseif canImport(AppKit)

// MARK: - Observable Adapter

fileprivate final class SectionLayoutsAdapter: ObservableObject {
    @Published var layouts: [SectionLayout] = []
}

// MARK: - AppKit View Controller

public class HomeDiscoverViewController: NSViewController {
    private var sectionLayouts: [SectionLayout] = []
    private var viewModel: HomeDiscoverViewModel?
    private var cancellables = Set<AnyCancellable>()
    private let layoutAdapter = SectionLayoutsAdapter()
    private var hostingView: NSHostingView<HomeDiscoverMacContentView>?

    public var onItemTapped: (() -> Void)?
    public var onGenreTapped: ((Genre) -> Void)?
    public var onTVGenreTapped: ((Genre) -> Void)?
    public var onCastTapped: ((PopularPerson) -> Void)?
    public var onTrendingItemTapped: ((TrendingItem) -> Void)?

    public init(viewModel: HomeDiscoverViewModel? = nil) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupDefaultSectionLayouts()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDefaultSectionLayouts()
    }

    public override func loadView() {
        self.view = NSView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor

        embedSwiftUIView()
        setupBindings()
        fetchDataIfNeeded()
        reloadContent()
    }

    public func configure(with sectionLayouts: [SectionLayout]) {
        self.sectionLayouts = sectionLayouts
        reloadContent()
    }

    public func updateSectionVisibility(at index: Int, isVisible: Bool) {
        guard index < sectionLayouts.count else { return }
        let existingLayout = sectionLayouts[index]
        sectionLayouts[index] = SectionLayout(
            type: existingLayout.type,
            height: existingLayout.height,
            data: existingLayout.data,
            headerTitle: existingLayout.headerTitle,
            isVisible: isVisible,
            onItemTapped: existingLayout.onItemTapped
        )
        reloadContent()
    }

    // MARK: - Private Helpers

    private func embedSwiftUIView() {
        let contentView = HomeDiscoverMacContentView(
            adapter: layoutAdapter,
            onCloseSection: { [weak self] index in
                self?.updateSectionVisibility(at: index, isVisible: false)
            }
        )
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        self.hostingView = hostingView
    }

    private func reloadContent() {
        layoutAdapter.layouts = sectionLayouts
    }

    private func setupDefaultSectionLayouts() {
        let movieGenreItems = mapGenresToPillShapeItems()
        let tvGenreItems = mapTVGenresToPillShapeItems()

        sectionLayouts = [
            SectionLayout(
                type: .categories,
                height: 50,
                data: movieGenreItems,
                headerTitle: "Movie Genres",
                onItemTapped: { index in
                    guard movieGenreItems.indices.contains(index) else { return }
                    movieGenreItems[index].selection?()
                }
            ),
            SectionLayout(
                type: .categories,
                height: 50,
                data: tvGenreItems,
                headerTitle: "TV Genres",
                onItemTapped: { index in
                    guard tvGenreItems.indices.contains(index) else { return }
                    tvGenreItems[index].selection?()
                }
            ),
            SectionLayout(
                type: .popularCategories,
                height: 140,
                data: mapPopularPeopleToCircleItems(),
                headerTitle: "Popular People",
                onItemTapped: { [weak self] index in
                    guard let self = self, let vm = self.viewModel, vm.popularPeople.indices.contains(index) else { return }
                    let person = vm.popularPeople[index]
                    self.onCastTapped?(person)
                }
            ),
            SectionLayout(
                type: .favourites,
                height: 180,
                data: mapTrendingToFavouriteListings(),
                headerTitle: "Trending",
                onItemTapped: { [weak self] index in
                    guard let self = self, let vm = self.viewModel, vm.trendingItems.indices.contains(index) else { return }
                    let trendingItem = vm.trendingItems[index]
                    self.onTrendingItemTapped?(trendingItem)
                }
            ),
        ]
    }

    private func mapGenresToPillShapeItems() -> [PillShapeItem] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.genres.map { genre in
            PillShapeItem(
                name: genre.name,
                imageSource: .sfSymbolName("tag"),
                selection: { [weak self] in
                    self?.onGenreTapped?(genre)
                }
            )
        }
    }

    private func mapTVGenresToPillShapeItems() -> [PillShapeItem] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.tvGenres.map { genre in
            PillShapeItem(
                name: genre.name,
                imageSource: .sfSymbolName("tv"),
                selection: { [weak self] in
                    self?.onTVGenreTapped?(genre)
                }
            )
        }
    }

    private func mapPopularPeopleToCircleItems() -> [CircleItem] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.popularPeople.map { person in
            CircleItem(
                name: person.name,
                imageSource: person.profilePath != nil
                    ? .imageUrl(TMDBImageSize.profileMedium.buildImageUrl(path: person.profilePath!)!)
                    : .sfSymbolName("person.circle")
            )
        }
    }

    private func mapTrendingToFavouriteListings() -> [FavouriteListing] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.trendingItems.map { item in
            FavouriteListing(
                imageSource: item.posterPath != nil
                    ? .imageUrl(TMDBImageSize.backdropSmall.buildImageUrl(path: item.posterPath!)!)
                    : .sfSymbolName("photo"),
                price: "\(item.mediaType.rawValue.capitalized)",
                title: item.displayTitle
            )
        }
    }

    private func setupBindings() {
        guard let viewModel = viewModel else { return }

        viewModel.$genres
            .combineLatest(viewModel.$tvGenres, viewModel.$popularPeople, viewModel.$trendingItems)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _, _ in
                self?.updateSectionLayouts()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.handleLoadingState(isLoading)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }

    private func fetchDataIfNeeded() {
        guard let viewModel = viewModel else { return }
        viewModel.fetchAllData()
    }

    private func updateSectionLayouts() {
        setupDefaultSectionLayouts()
        reloadContent()
    }

    private func handleLoadingState(_ isLoading: Bool) {
        view.alphaValue = isLoading ? 0.5 : 1.0
    }

    private func handleError(_ errorMessage: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = errorMessage
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning
        if let window = view.window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
}

// MARK: - SwiftUI Content View

fileprivate struct HomeDiscoverMacContentView: View {
    @ObservedObject var adapter: SectionLayoutsAdapter
    var onCloseSection: (Int) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Array(adapter.layouts.enumerated()), id: \.offset) { index, layout in
                    if layout.isVisible {
                        sectionBlock(for: layout, index: index)
                    }
                }
            }
            .padding(24)
        }
        .background(Color.black)
    }

    @ViewBuilder
    private func sectionBlock(for layout: SectionLayout, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = layout.headerTitle {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            sectionContent(for: layout, index: index)
        }
    }

    @ViewBuilder
    private func sectionContent(for layout: SectionLayout, index: Int) -> some View {
        switch layout.type {
        case .banner:
            BannerCard(onClose: { onCloseSection(index) })

        case .categories:
            if let items = layout.data as? [PillShapeItem] {
                CategoriesRow(items: items, layout: layout)
            }

        case .popularCategories:
            if let items = layout.data as? [CircleItem] {
                PopularRow(items: items, layout: layout)
            }

        case .favourites:
            if let items = layout.data as? [FavouriteListing] {
                FavouritesRow(items: items, layout: layout)
            }
        }
    }
}

// MARK: - SwiftUI Components

fileprivate struct BannerCard: View {
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text("Quick post with AI")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("List your items for sale in a jiffy")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(red: 0.2, green: 0.2, blue: 0.4))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

fileprivate struct CategoriesRow: View {
    let items: [PillShapeItem]
    let layout: SectionLayout

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button(action: {
                        layout.onItemTapped(index)
                    }) {
                        HStack(spacing: 8) {
                            DiscoverImageView(source: item.imageSource)
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                            Text(item.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.2, green: 0.2, blue: 0.4))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

fileprivate struct PopularRow: View {
    let items: [CircleItem]
    let layout: SectionLayout

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 6) {
                        DiscoverImageView(source: item.imageSource)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        Text(item.name)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: 90)
                    }
                    .onTapGesture {
                        layout.onItemTapped(index)
                    }
                }
            }
        }
    }
}

fileprivate struct FavouritesRow: View {
    let items: [FavouriteListing]
    let layout: SectionLayout

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, listing in
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .topTrailing) {
                            DiscoverImageView(source: listing.imageSource)
                                .frame(width: 150, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )

                            Image(systemName: "heart")
                                .foregroundColor(.white)
                                .padding(6)
                        }

                        Text(listing.price)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Text(listing.title)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                    .frame(width: 150, alignment: .leading)
                    .onTapGesture {
                        layout.onItemTapped(index)
                    }
                }
            }
        }
    }
}

fileprivate struct DiscoverImageView: View {
    let source: ImageSource

    var body: some View {
        switch source {
        case .sfSymbolName(let name):
            Image(systemName: name)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)

        case .assetName(let name):
            if let image = NSImage(named: name) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }

        case .imageUrl(let url):
            KFImage(url)
                .resizable()
                .scaledToFill()
        }
    }

    private var placeholder: some View {
        Color.gray.opacity(0.3)
    }
}

#endif
