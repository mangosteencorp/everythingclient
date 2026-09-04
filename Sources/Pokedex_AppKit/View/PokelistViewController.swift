#if canImport(AppKit) && !canImport(UIKit)
import AppKit

/// The AppKit counterpart of `Pokedex_Pokelist.PokelistViewController`.
///
/// Same VIPER role and the same paging behaviour; the differences are all AppKit-shaped:
/// `NSCollectionView` has to live inside an `NSScrollView`, items are `NSCollectionViewItem`
/// (a view *controller*, not a cell), and paging keys off `willDisplayItem` because AppKit has
/// no `scrollViewDidScroll` delegate callback on the collection view itself.
public final class PokelistViewController: NSViewController, PokelistViewProtocol {
    public var presenter: PokelistPresenterProtocol?

    private let scrollView = NSScrollView()
    private let collectionView = NSCollectionView()
    private let spinner: NSProgressIndicator = {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.isDisplayedWhenStopped = false
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    override public func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureSpinner()
        presenter?.viewDidLoad()
    }

    override public func viewWillDisappear() {
        super.viewWillDisappear()
        // Mirrors the iOS module: without this the presenter's `isLoading` flag stays true and
        // blocks every later page.
        presenter?.cancelLoading()
    }

    // MARK: - Layout

    private func configureCollectionView() {
        collectionView.collectionViewLayout = Self.makeLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true
        collectionView.backgroundColors = [.clear]
        collectionView.register(
            PokemonCollectionViewItem.self,
            forItemWithIdentifier: PokemonCollectionViewItem.reuseIdentifier
        )

        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func configureSpinner() {
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    /// Adaptive grid: as many ~140pt tiles as the window width allows.
    private static func makeLayout() -> NSCollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(160)
            ),
            subitem: item,
            count: 3
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        return NSCollectionViewCompositionalLayout(section: section)
    }

    // MARK: - PokelistViewProtocol

    public func showPokemons() {
        collectionView.reloadData()
    }

    public func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Could not load Pokémon"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        if let window = view.window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    public func showLoading() {
        spinner.startAnimation(nil)
    }

    public func hideLoading() {
        spinner.stopAnimation(nil)
    }
}

// MARK: - NSCollectionViewDataSource

extension PokelistViewController: NSCollectionViewDataSource {
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        presenter?.getPokemons().count ?? 0
    }

    public func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        let item = collectionView.makeItem(
            withIdentifier: PokemonCollectionViewItem.reuseIdentifier,
            for: indexPath
        )
        guard let pokemonItem = item as? PokemonCollectionViewItem,
              let pokemon = presenter?.getPokemons()[safe: indexPath.item] else {
            return item
        }
        pokemonItem.configure(with: pokemon)
        return pokemonItem
    }
}

// MARK: - NSCollectionViewDelegate

extension PokelistViewController: NSCollectionViewDelegate {
    public func collectionView(
        _ collectionView: NSCollectionView,
        willDisplay item: NSCollectionViewItem,
        forRepresentedObjectAt indexPath: IndexPath
    ) {
        // AppKit gives no scroll callback on the collection view, so the last row is the trigger.
        let count = presenter?.getPokemons().count ?? 0
        if indexPath.item >= count - 4 {
            presenter?.loadMorePokemons()
        }
    }

    public func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        collectionView.deselectItems(at: indexPaths)
        presenter?.didSelectPokemon(at: indexPath.item)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
#endif
