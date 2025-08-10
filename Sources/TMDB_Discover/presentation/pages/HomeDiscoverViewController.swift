
import Combine
import Kingfisher
import TMDB_Shared_Backend
import UIKit

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

fileprivate struct PillShapeItem {
    let name: String
    let imageSource: ImageSource
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
    public var onCastTapped: ((PopularPerson) -> Void)?

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
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
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
        sectionLayouts = [
            SectionLayout(
                type: .categories,
                height: 50,
                data: mapGenresToPillShapeItems(),
                headerTitle: "Genres",
                onItemTapped: { index in
                    if let vm = self.viewModel, vm.genres.indices.contains(index) {
                        let genre = vm.genres[index]
                        self.onGenreTapped?(genre)
                    }
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
                onItemTapped: { _ in
                    self.onItemTapped?()
                }
            ),
        ]
    }

    private func mapGenresToPillShapeItems() -> [PillShapeItem] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.genres.map { genre in
            PillShapeItem(
                name: genre.name,
                imageSource: .sfSymbolName("tag")
            )
        }
    }

    private func mapPopularPeopleToCircleItems() -> [CircleItem] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.popularPeople.map { person in
            CircleItem(
                name: person.name,
                imageSource: person.profilePath != nil
                    ? .imageUrl(URL(string: "https://image.tmdb.org/t/p/w200\(person.profilePath!)")!)
                    : .sfSymbolName("person.circle")
            )
        }
    }

    private func mapTrendingToFavouriteListings() -> [FavouriteListing] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.trendingItems.map { item in
            FavouriteListing(
                imageSource: item.posterPath != nil
                    ? .imageUrl(URL(string: "https://image.tmdb.org/t/p/w300\(item.posterPath!)")!)
                    : .sfSymbolName("photo"),
                price: "\(item.mediaType.capitalized)",
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
            .combineLatest(viewModel.$popularPeople, viewModel.$trendingItems)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
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

        switch sectionLayout.type {
        case .categories:
            // Handle genre selection
            if let viewModel = viewModel, row < viewModel.genres.count {
                let genre = viewModel.genres[row]
                onGenreTapped?(genre)
            }
        case .popularCategories:
            // Handle cast selection
            if let viewModel = viewModel, row < viewModel.popularPeople.count {
                let person = viewModel.popularPeople[row]
                onCastTapped?(person)
            }
        case .favourites:
            // Handle trending item selection
            if let viewModel = viewModel, row < viewModel.trendingItems.count {
                onItemTapped?()
            }
        default:
            // Default behavior for other sections
            onItemTapped?()
        }
    }
}

#if DEBUG
fileprivate let exampleMovieRespository = MovieRepositoryImpl(apiService: TMDBAPIService.init(apiKey: debugTMDBAPIKey))
/// Grok: https://grok.com/chat/a4c29db6-3c12-4221-b134-490e4015d4d4
@available(iOS 17, *)
#Preview {
    HomeDiscoverViewController(
        viewModel:
            HomeDiscoverViewModel(
                fetchGenresUseCase:
                    DefaultFetchGenresUseCase(repository: exampleMovieRespository),
                fetchPopularPeopleUseCase: DefaultFetchPopularPeopleUseCase(repository: exampleMovieRespository),
                fetchTrendingItemsUseCase: DefaultFetchTrendingItemsUseCase(repository: exampleMovieRespository)))
}
#endif

// MARK: - SwiftUI Wrapper
