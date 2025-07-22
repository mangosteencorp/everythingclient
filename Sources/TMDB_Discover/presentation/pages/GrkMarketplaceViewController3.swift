
import UIKit
import Kingfisher
import Combine
import TMDB_Shared_Backend
// MARK: - Section Layout Configuration
struct SectionLayout {
    enum SectionType {
        case banner
        case categories
        case popularCategories
        case favourites
    }
    
    let type: SectionType
    let height: CGFloat
    let data: [Any]
    let headerTitle: String?
    let isVisible: Bool
    
    init(type: SectionType, height: CGFloat, data: [Any], headerTitle: String? = nil, isVisible: Bool = true) {
        self.type = type
        self.height = height
        self.data = data
        self.headerTitle = headerTitle
        self.isVisible = isVisible
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
            closeButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    @objc private func closeTapped() {
        onCloseTapped?()
    }
}

fileprivate class HorizontalCollectionCell: UICollectionViewCell, UICollectionViewDataSource {
    static let reuseIdentifier: String = "HorizontalCollectionCell"
    
    enum SectionType {
        case categories
        case popularCategories
        case favourites
    }
    
    var sectionType: SectionType?
    var data: [Any] = []
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.dataSource = self
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        switch sectionType {
        case .categories:
            collectionView.register(PillShapeItemCell.self, forCellWithReuseIdentifier: PillShapeItemCell.reuseIdentifier)
            flowLayout.itemSize = CGSize(width: 120, height: 40)
            flowLayout.minimumInteritemSpacing = 10
        case .popularCategories:
            collectionView.register(CircleItemCell.self, forCellWithReuseIdentifier: CircleItemCell.reuseIdentifier)
            flowLayout.itemSize = CGSize(width: 100, height: 120)
            flowLayout.minimumInteritemSpacing = 15
        case .favourites:
            collectionView.register(FavouriteListingCell.self, forCellWithReuseIdentifier: FavouriteListingCell.reuseIdentifier)
            flowLayout.itemSize = CGSize(width: 150, height: 160)
            flowLayout.minimumInteritemSpacing = 15
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch sectionType {
        case .categories:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PillShapeItemCell.reuseIdentifier, for: indexPath) as! PillShapeItemCell
            let item = data[indexPath.item] as! PillShapeItem
            cell.configure(with: item)
            return cell
        case .popularCategories:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CircleItemCell.reuseIdentifier, for: indexPath) as! CircleItemCell
            let item = data[indexPath.item] as! CircleItem
            cell.configure(with: item)
            return cell
        case .favourites:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavouriteListingCell.reuseIdentifier, for: indexPath) as! FavouriteListingCell
            let listing = data[indexPath.item] as! FavouriteListing
            cell.configure(with: listing)
            return cell
        default:
            return UICollectionViewCell()
        }
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
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
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
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
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
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
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
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

// MARK: - Main View Controller
class GrkMarketplaceViewController3: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    private var sectionLayouts: [SectionLayout] = []
    private var viewModel: HomeDiscoverViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    // MARK: - Initialization
    init(viewModel: HomeDiscoverViewModel? = nil) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupDefaultSectionLayouts()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupDefaultSectionLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDefaultSectionLayouts()
    }
    
    // MARK: - Public Methods
    func configure(with sectionLayouts: [SectionLayout]) {
        self.sectionLayouts = sectionLayouts
        collectionView.reloadData()
    }
    
    func updateSectionVisibility(at index: Int, isVisible: Bool) {
        guard index < sectionLayouts.count else { return }
        sectionLayouts[index] = SectionLayout(
            type: sectionLayouts[index].type,
            height: sectionLayouts[index].height,
            data: sectionLayouts[index].data,
            headerTitle: sectionLayouts[index].headerTitle,
            isVisible: isVisible
        )
        collectionView.reloadData()
    }
    
    // MARK: - Private Methods
    private func setupDefaultSectionLayouts() {
        sectionLayouts = [
            SectionLayout(
                type: .categories,
                height: 50,
                data: mapGenresToPillShapeItems(),
                headerTitle: "Genres"
            ),
            SectionLayout(
                type: .popularCategories,
                height: 140,
                data: mapPopularPeopleToCircleItems(),
                headerTitle: "Popular People"
            ),
            SectionLayout(
                type: .favourites,
                height: 180,
                data: mapTrendingToFavouriteListings(),
                headerTitle: "Trending"
            )
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.reuseIdentifier)
        collectionView.register(HorizontalCollectionCell.self, forCellWithReuseIdentifier: HorizontalCollectionCell.reuseIdentifier)
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
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionLayouts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let layout = sectionLayouts[section]
        return layout.isVisible ? 1 : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let layout = sectionLayouts[indexPath.section]
        
        switch layout.type {
        case .banner:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.reuseIdentifier, for: indexPath) as! BannerCell
            cell.onCloseTapped = { [weak self] in
                self?.updateSectionVisibility(at: indexPath.section, isVisible: false)
            }
            return cell
            
        case .categories, .popularCategories, .favourites:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HorizontalCollectionCell.reuseIdentifier, for: indexPath) as! HorizontalCollectionCell
            
            switch layout.type {
            case .categories:
                cell.sectionType = .categories
            case .popularCategories:
                cell.sectionType = .popularCategories
            case .favourites:
                cell.sectionType = .favourites
            default:
                break
            }
            
            cell.data = layout.data
            cell.collectionView.reloadData()
            return cell
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let layout = sectionLayouts[indexPath.section]
        return CGSize(width: width, height: layout.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let layout = sectionLayouts[section]
        if layout.headerTitle != nil {
            return CGSize(width: collectionView.bounds.width, height: 30)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let layout = sectionLayouts[indexPath.section]
            if let headerTitle = layout.headerTitle {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.reuseIdentifier, for: indexPath) as! SectionHeaderView
                header.titleLabel.text = headerTitle
                return header
            }
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
    }
}

#if DEBUG
fileprivate let exampleMovieRespository = MovieRepositoryImpl(apiService: TMDBAPIService.init(apiKey: debugTMDBAPIKey))
/// Grok: https://grok.com/chat/a4c29db6-3c12-4221-b134-490e4015d4d4
@available(iOS 17, *)
#Preview {
    GrkMarketplaceViewController3(
        viewModel:
            HomeDiscoverViewModel(
                fetchGenresUseCase:
                    DefaultFetchGenresUseCase(repository: exampleMovieRespository),
                fetchPopularPeopleUseCase: DefaultFetchPopularPeopleUseCase(repository: exampleMovieRespository),
                fetchTrendingItemsUseCase: DefaultFetchTrendingItemsUseCase(repository: exampleMovieRespository)))
}
#endif
