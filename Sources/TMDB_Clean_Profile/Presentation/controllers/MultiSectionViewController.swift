import Foundation
import UIKit
import SwiftUI
import Kingfisher
// MARK: - Section Type Enum
enum SectionType: String, Codable {
    case featured = "featured"
    case mediumTable = "mediumTable"
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
        sections.forEach { section in
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
        collectionView = UICollectionView(frame: view.bounds,
                                        collectionViewLayout: createCompositionalLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        view.addSubview(collectionView)
        
        // Register cells
        collectionView.register(FeaturedCell.self,
                              forCellWithReuseIdentifier: FeaturedCell.reuseIdentifier)
        collectionView.register(MediumTableCell.self,
                              forCellWithReuseIdentifier: MediumTableCell.reuseIdentifier)
    }
    
    private func configure<C: SelfConfiguringCell>(_ cellType: C.Type, with item: T,
                                                 for indexPath: IndexPath) -> C {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.reuseIdentifier,
                                                          for: indexPath) as? C else {
            fatalError("Unable to dequeue \(cellType)")
        }
        cell.configure(with: item)
        return cell
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section<T>, T>(
            collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self = self else { return nil }
            
            switch self.sections[indexPath.section].type {
            case .mediumTable:
                return self.configure(MediumTableCell.self, with: item, for: indexPath)
            case .featured:
                return self.configure(FeaturedCell.self, with: item, for: indexPath)
            }
        }
    }
    
    private func reloadData(animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section<T>, T>()
        snapshot.appendSections(sections)
        sections.forEach { section in
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
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                            heightDimension: .fractionalHeight(1))
        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
        layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5,
                                                         bottom: 0, trailing: 5)
        
        let layoutGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.93),
                                                   heightDimension: .estimated(350))
        let layoutGroup = NSCollectionLayoutGroup.horizontal(layoutSize: layoutGroupSize,
                                                           subitems: [layoutItem])
        
        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        return layoutSection
    }
    
    private func createMediumTableSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                            heightDimension: .fractionalHeight(0.33))
        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
        layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5,
                                                         bottom: 0, trailing: 5)
        
        let layoutGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.93),
                                                   heightDimension: .fractionalWidth(0.55))
        let layoutGroup = NSCollectionLayoutGroup.vertical(layoutSize: layoutGroupSize,
                                                         subitems: [layoutItem])
        
        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.orthogonalScrollingBehavior = .groupPagingCentered
        return layoutSection
    }
}

// MARK: - Cell Implementations
class FeaturedCell: UICollectionViewCell, SelfConfiguringCell {
    static var reuseIdentifier: String = "FeaturedCell"
    
    private let tagline = UILabel()
    private let name = UILabel()
    private let subtitle = UILabel()
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        tagline.font = UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: 12, weight: .bold))
        tagline.textColor = .systemBlue
        
        name.font = UIFont.preferredFont(forTextStyle: .title2)
        name.textColor = .label
        
        subtitle.font = .preferredFont(forTextStyle: .title2)
        subtitle.textColor = .secondaryLabel
        
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        
        let stackView = UIStackView(arrangedSubviews: [tagline, name, subtitle, imageView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        stackView.setCustomSpacing(10, after: subtitle)
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
    
    private let name = UILabel()
    private let subtitle = UILabel()
    private let imageView = UIImageView()
    private let buyButton = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        name.font = .preferredFont(forTextStyle: .headline)
        name.textColor = .label
        
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = .secondaryLabel
        
        imageView.layer.cornerRadius = 15
        imageView.clipsToBounds = true
        
        buyButton.setImage(UIImage(systemName: "icloud.and.arrow.down"), for: .normal)
        
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        buyButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let innerStackView = UIStackView(arrangedSubviews: [name, subtitle])
        innerStackView.axis = .vertical
        
        let outerStackView = UIStackView(arrangedSubviews: [imageView, innerStackView, buyButton])
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        outerStackView.spacing = 10
        contentView.addSubview(outerStackView)
        
        NSLayoutConstraint.activate([
            outerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            outerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            outerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            outerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure<T: CollectionItem>(with item: T) {
        name.text = item.name
        subtitle.text = item.subheading
        imageView.kf.setImage(with: item.imageURL)
    }
}
