import Foundation
import Kingfisher
import Shared_UI_Support
import SwiftUI
import UIKit

// MARK: - Section Type Enum

enum SectionType: String, Codable {
    case featured
    case mediumTable
}

// MARK: - Models

protocol CollectionItem: Hashable, Codable {
    var id: Int { get }
    var imageURL: URL { get }
    var name: String { get }
    var tagline: String { get }
    var subheading: String { get }
}

struct Section<T: CollectionItem>: Hashable {
    let id: Int
    let type: SectionType
    let title: String
    let subtitle: String
    let items: [T]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Section<T>, rhs: Section<T>) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Delegate Protocol

protocol MultiSectionViewControllerDelegate: AnyObject {
    func didSelectItem<T: CollectionItem>(_ item: T, in section: Section<T>)
}

// MARK: - Cell Protocol

protocol SelfConfiguringCell {
    static var reuseIdentifier: String { get }
    func configure<T: CollectionItem>(with item: T)
}

// MARK: - View Controller

class MultiSectionViewController<T: CollectionItem>: UIViewController, UICollectionViewDelegate {
    // MARK: Properties

    private var sections: [Section<T>]
    private weak var delegate: MultiSectionViewControllerDelegate?
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section<T>, T>?

    // MARK: Initialization

    init(sections: [Section<T>], delegate: MultiSectionViewControllerDelegate? = nil) {
        self.sections = sections
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupDataSource()
        reloadData()
    }

    // MARK: Public Methods

    func updateSections(_ newSections: [Section<T>], animatingDifferences: Bool = true) {
        sections = newSections
        var snapshot = NSDiffableDataSourceSnapshot<Section<T>, T>()
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(section.items, toSection: section)
        }
        dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    func appendItems(_ items: [T], to section: Section<T>, animatingDifferences: Bool = true) {
        guard let sectionIndex = sections.firstIndex(where: { $0.id == section.id }) else { return }

        // Create new section with combined items
        let updatedSection = Section<T>(
            id: section.id,
            type: section.type,
            title: section.title,
            subtitle: section.subtitle,
            items: section.items + items
        )

        var snapshot = dataSource?.snapshot() ?? NSDiffableDataSourceSnapshot<Section<T>, T>()
        snapshot.appendItems(items, toSection: section)

        // Update sections array with new section
        sections[sectionIndex] = updatedSection

        dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    func deleteItems(_ items: [T], animatingDifferences: Bool = true) {
        var snapshot = dataSource?.snapshot() ?? NSDiffableDataSourceSnapshot<Section<T>, T>()
        snapshot.deleteItems(items)
        dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)

        // Update sections array with new sections containing filtered items
        sections = sections.map { section in
            Section<T>(
                id: section.id,
                type: section.type,
                title: section.title,
                subtitle: section.subtitle,
                items: section.items.filter { !items.contains($0) }
            )
        }
    }

    // MARK: Private Methods

    private func setupCollectionView() {
        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: createCompositionalLayout()
        )
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        view.addSubview(collectionView)

        // Register cells
        collectionView.register(
            FeaturedCell.self,
            forCellWithReuseIdentifier: FeaturedCell.reuseIdentifier
        )
        collectionView.register(
            MediumTableCell.self,
            forCellWithReuseIdentifier: MediumTableCell.reuseIdentifier
        )
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )
    }

    private func configure<C: SelfConfiguringCell>(
        _ cellType: C.Type,
        with item: T,
        for indexPath: IndexPath
    ) -> C {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellType.reuseIdentifier,
            for: indexPath
        ) as? C else {
            fatalError("Unable to dequeue \(cellType)")
        }
        cell.configure(with: item)
        return cell
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section<T>, T>(
            collectionView: collectionView
        ) { [weak self] _, indexPath, item in
            guard let self = self else { return nil }

            switch self.sections[indexPath.section].type {
            case .mediumTable:
                return self.configure(MediumTableCell.self, with: item, for: indexPath)
            case .featured:
                return self.configure(FeaturedCell.self, with: item, for: indexPath)
            }
        }

        dataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self = self,
                  kind == UICollectionView.elementKindSectionHeader,
                  let header = collectionView.dequeueReusableSupplementaryView(
                      ofKind: kind,
                      withReuseIdentifier: SectionHeaderView.reuseIdentifier,
                      for: indexPath
                  ) as? SectionHeaderView
            else { return nil }

            let section = self.sections[indexPath.section]
            header.configure(title: section.title, subtitle: section.subtitle)
            return header
        }
    }

    private func reloadData(animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section<T>, T>()
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(section.items, toSection: section)
        }
        dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let item = section.items[indexPath.item]
        delegate?.didSelectItem(item, in: section)
    }

    private func createCompositionalLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self = self else { return nil }
            let section = self.sections[sectionIndex]

            switch section.type {
            case .mediumTable:
                return self.createMediumTableSection()
            case .featured:
                return self.createFeaturedSection()
            }
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20
        layout.configuration = config
        return layout
    }

    private func createFeaturedSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
        layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

        let layoutGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.85),
            heightDimension: .absolute(200)
        )
        let layoutGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: layoutGroupSize,
            subitems: [layoutItem]
        )

        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.orthogonalScrollingBehavior = .groupPagingCentered
        layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(60)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        layoutSection.boundarySupplementaryItems = [header]

        return layoutSection
    }

    private func createMediumTableSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(70)
        )
        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
        layoutItem.contentInsets = NSDirectionalEdgeInsets(
            top: 4, leading: 8, bottom: 4, trailing: 8
        )

        // Create a vertical group with 3 items
        let columnGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.8), // Width of each column
            heightDimension: .absolute(234) // Height to fit 3 items
        )
        let columnGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: columnGroupSize,
            subitem: layoutItem,
            count: 3 // 3 items per column
        )

        let layoutSection = NSCollectionLayoutSection(group: columnGroup)
        layoutSection.orthogonalScrollingBehavior = .groupPaging // Enable horizontal scrolling
        layoutSection.contentInsets = NSDirectionalEdgeInsets(
            top: 8, leading: 16, bottom: 8, trailing: 16
        )

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(60)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        layoutSection.boundarySupplementaryItems = [header]

        return layoutSection
    }
}

// MARK: - Cell Implementations

class FeaturedCell: UICollectionViewCell, SelfConfiguringCell {
    static var reuseIdentifier: String = "FeaturedCell"

    private let containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor,
        ]
        layer.locations = [0.5, 1.0]
        return layer
    }()

    private let tagline: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let name: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let subtitle: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.8)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
    }

    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.layer.addSublayer(gradientLayer)

        let textStack = UIStackView(arrangedSubviews: [tagline, name, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 4
        containerView.addSubview(textStack)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            textStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
        ])
    }

    func configure<T: CollectionItem>(with item: T) {
        tagline.text = item.tagline.uppercased()
        name.text = item.name
        subtitle.text = item.subheading
        imageView.kf.setImage(with: item.imageURL)
    }
}

class MediumTableCell: UICollectionViewCell, SelfConfiguringCell {
    static var reuseIdentifier: String = "MediumTableCell"

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private let name: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let subtitle: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(containerView)

        let textStack = UIStackView(arrangedSubviews: [name, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 4

        for item in [imageView, textStack] {
            containerView.addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 50),
            imageView.heightAnchor.constraint(equalToConstant: 50),

            textStack.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            textStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
    }

    func configure<T: CollectionItem>(with item: T) {
        name.text = item.name
        subtitle.text = item.subheading
        imageView.kf.setImage(with: item.imageURL)
    }
}

class SectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "SectionHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 4

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}

//swiftlint:disable all
#if DEBUG
let sampleSections: [Section<ProfileCollectionItem>] = [
    // Featured Section (Watchlist)
    Section(
        id: 1,
        type: .featured,
        title: "Watchlist",
        subtitle: "Shows you want to watch",
        items: [
            ProfileCollectionItem(
                id: 251_691,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w500/8uDmIxjBx90y5OCwJDBADtQzxb7.jpg")!,
                name: "Autumn of the Heart",
                tagline: "TV Show",
                subheading: "First aired: 2024-10-27"
            ),
            ProfileCollectionItem(
                id: 2734,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w500/abWOCrIo7bbAORxcQyOFNJdnnmR.jpg")!,
                name: "Law & Order: Special Victims Unit",
                tagline: "TV Show",
                subheading: "First aired: 1999-09-20"
            ),
        ]
    ),

    // Medium Table Section (Favorite TV Shows)
    Section(
        id: 2,
        type: .mediumTable,
        title: "Favorite TV Shows",
        subtitle: "Your top picks",
        items: [
            ProfileCollectionItem(
                id: 251_691,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/8uDmIxjBx90y5OCwJDBADtQzxb7.jpg")!,
                name: "Autumn of the Heart",
                tagline: "4.2★",
                subheading: "A devastating car accident unearths a long-buried secret that turns wealthy businessman Rashid and hardworking Nahla's life around; fifteen years ago, their daughters were switched at birth."
            ),
            ProfileCollectionItem(
                id: 2734,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/abWOCrIo7bbAORxcQyOFNJdnnmR.jpg")!,
                name: "Law & Order: Special Victims Unit",
                tagline: "7.9★",
                subheading: "In the criminal justice system, sexually-based offenses are considered especially heinous. In New York City, the dedicated detectives who investigate these vicious felonies are members of an elite squad known as the Special Victims Unit. These are their stories."
            ),
            ProfileCollectionItem(
                id: 273_327,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/xrGx7uRbCc9qwU76YD2wJXL56Js.jpg")!,
                name: "Black Point",
                tagline: "0.0★",
                subheading: "\"Black Point\" takes place in a social romantic setting, exploring the complex relationships between its diverse characters."
            ),
            ProfileCollectionItem(
                id: 61583,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/fnuPYgBw5UriMqE6bfrtbjZlrqH.jpg")!,
                name: "Cuarto milenio",
                tagline: "7.5★",
                subheading: ""
            ),
            ProfileCollectionItem(
                id: 206_559,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/3bzECfllho8PphdYujLUIuhncJD.jpg")!,
                name: "Binnelanders",
                tagline: "5.6★",
                subheading: "A South African Afrikaans soap opera. It is set in and around the fictional private hospital, Binneland Kliniek, in Pretoria, and the storyline follows the trials, trauma and tribulations of the staff and patients of the hospital."
            ),
            ProfileCollectionItem(
                id: 93405,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/dDlEmu3EZ0Pgg93K2SVNLCjCSvE.jpg")!,
                name: "Squid Game",
                tagline: "7.8★",
                subheading: "Hundreds of cash-strapped players accept a strange invitation to compete in children's games. Inside, a tempting prize awaits — with deadly high stakes."
            ),
        ]
    ),

    // Medium Table Section (Favorite Movies)
    Section(
        id: 3,
        type: .mediumTable,
        title: "Favorite Movies",
        subtitle: "Your movie collection",
        items: [
            ProfileCollectionItem(
                id: 1_184_918,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/9w0Vh9eizfBXrcomiaFWTIPdboo.jpg")!,
                name: "The Wild Robot",
                tagline: "8.4★",
                subheading: "After a shipwreck, an intelligent robot called Roz is stranded on an uninhabited island. To survive the harsh environment, Roz bonds with the island's animals and cares for an orphaned baby goose."
            ),
            ProfileCollectionItem(
                id: 238,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/3bhkrj58Vtu7enYsRolD1fZdja1.jpg")!,
                name: "The Godfather",
                tagline: "8.7★",
                subheading: "Spanning the years 1945 to 1955, a chronicle of the fictional Italian-American Corleone crime family. When organized crime family patriarch, Vito Corleone barely survives an attempt on his life, his youngest son, Michael steps in to take care of the would-be killers, launching a campaign of bloody revenge."
            ),
            ProfileCollectionItem(
                id: 912_649,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/aosm8NMQ3UyoBVpSxyimorCQykC.jpg")!,
                name: "Venom: The Last Dance",
                tagline: "6.8★",
                subheading: "Eddie and Venom are on the run. Hunted by both of their worlds and with the net closing in, the duo are forced into a devastating decision that will bring the curtains down on Venom and Eddie's last dance."
            ),
            ProfileCollectionItem(
                id: 939_243,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/x7NPbBlrvFRJrpinBSRlMOOUWom.jpg")!,
                name: "Sonic the Hedgehog 3",
                tagline: "7.7★",
                subheading: "Sonic, Knuckles, and Tails reunite against a powerful new adversary, Shadow, a mysterious villain with powers unlike anything they have faced before. With their abilities outmatched in every way, Team Sonic must seek out an unlikely alliance in hopes of stopping Shadow and protecting the planet."
            ),
            ProfileCollectionItem(
                id: 559_969,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/ePXuKdXZuJx8hHMNr2yM4jY2L7Z.jpg")!,
                name: "El Camino: A Breaking Bad Movie",
                tagline: "7.0★",
                subheading: "In the wake of his dramatic escape from captivity, Jesse Pinkman must come to terms with his past in order to forge some kind of future."
            ),
            ProfileCollectionItem(
                id: 475_557,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg")!,
                name: "Joker",
                tagline: "8.1★",
                subheading: "During the 1980s, a failed stand-up comedian is driven insane and turns to a life of crime and chaos in Gotham City while becoming an infamous psychopathic crime figure."
            ),
            ProfileCollectionItem(
                id: 103,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/ekstpH614fwDX8DUln1a2Opz0N8.jpg")!,
                name: "Taxi Driver",
                tagline: "8.1★",
                subheading: "A mentally unstable Vietnam War veteran works as a night-time taxi driver in New York City where the perceived decadence and sleaze feed his urge for violent action."
            ),
            ProfileCollectionItem(
                id: 426_063,
                imageURL: URL(string: "https://image.tmdb.org/t/p/w154/5qGIxdEO841C0tdY8vOdLoRVrr0.jpg")!,
                name: "Nosferatu",
                tagline: "6.8★",
                subheading: "A gothic tale of obsession between a haunted young woman and the terrifying vampire infatuated with her, causing untold horror in its wake."
            ),
        ]
    ),
]
#Preview {
    UIViewControllerPreview {
        MultiSectionViewController(sections: sampleSections)
    }
}
#endif
//swiftlint:enable all
