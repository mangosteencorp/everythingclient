#if canImport(UIKit)
import UIKit

public final class PokelistViewController: UIViewController {
    public var presenter: PokelistPresenterProtocol?
    private var isLoading = false

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        // swiftlint:disable identifier_name
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .black
        cv.register(PokemonCell.self, forCellWithReuseIdentifier: PokemonCell.reuseIdentifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
        // swiftlint:enable identifier_name
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        presenter?.viewDidLoad()
    }

    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
}

// MARK: - PokelistViewProtocol

extension PokelistViewController: PokelistViewProtocol {
    public func showPokemons() {
        collectionView.reloadData()
    }

    public func showError(_ error: Error) {
        // Implement error handling UI
        print("Error loading pokemons: \(error)")
    }

    public func showLoading() {
        isLoading = true
    }

    public func hideLoading() {
        isLoading = false
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension PokelistViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter?.getPokemons().count ?? 0
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PokemonCell.reuseIdentifier,
            for: indexPath
        ) as? PokemonCell,
            let pokemon = presenter?.getPokemons()[indexPath.item]
        else {
            return UICollectionViewCell()
        }

        cell.configure(with: pokemon)
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let padding: CGFloat = 16 * 2
        let spacing: CGFloat = 8
        let maxCellWidth: CGFloat = 180

        let availableWidth = collectionView.bounds.width - padding
        let numberOfColumns = max(2, Int(availableWidth / maxCellWidth))
        let totalSpacing = CGFloat(numberOfColumns - 1) * spacing
        let cellWidth = min(maxCellWidth, (availableWidth - totalSpacing) / CGFloat(numberOfColumns))

        return CGSize(width: cellWidth, height: cellWidth)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presenter?.didSelectPokemon(at: indexPath.item)
    }
}

// MARK: - UIScrollViewDelegate

extension PokelistViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = scrollView.frame.size.height

        if offsetY > contentHeight - screenHeight - 100 {
            presenter?.loadMorePokemons()
        }
    }
}

#elseif canImport(AppKit)
import AppKit
import SwiftUI
import Combine

final class PokelistViewController: NSViewController {
    public var presenter: PokelistPresenterProtocol?
    private let adapter = PokelistMacAdapter()
    private var hostingView: NSHostingView<PokelistMacView>?

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter?.viewDidLoad()
    }

    private func setupView() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor

        let contentView = PokelistMacView(
            adapter: adapter,
            onSelect: { [weak self] pokemon in
                guard
                    let self = self,
                    let index = self.presenter?.getPokemons().firstIndex(where: { $0.id == pokemon.id })
                else { return }
                self.presenter?.didSelectPokemon(at: index)
            },
            onLoadMore: { [weak self] in
                self?.presenter?.loadMorePokemons()
            }
        )

        let hosting = NSHostingView(rootView: contentView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)

        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        hostingView = hosting
    }
}

extension PokelistViewController: PokelistViewProtocol {
    public func showPokemons() {
        DispatchQueue.main.async {
            self.adapter.pokemons = self.presenter?.getPokemons() ?? []
        }
    }

    public func showError(_ error: Error) {
        DispatchQueue.main.async {
            self.adapter.present(error: error)
        }
    }

    public func showLoading() {
        DispatchQueue.main.async {
            self.adapter.isLoading = true
        }
    }

    public func hideLoading() {
        DispatchQueue.main.async {
            self.adapter.isLoading = false
        }
    }
}

private final class PokelistMacAdapter: ObservableObject {
    @Published var pokemons: [PokemonEntity] = []
    @Published var isLoading = false
    @Published var presentedError: PokelistErrorWrapper?

    func present(error: Error) {
        presentedError = PokelistErrorWrapper(message: error.localizedDescription)
    }
}

private struct PokelistErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

private struct PokelistMacView: View {
    @ObservedObject var adapter: PokelistMacAdapter
    var onSelect: (PokemonEntity) -> Void
    var onLoadMore: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 16, alignment: .top),
    ]

    var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(adapter.pokemons, id: \.id) { pokemon in
                        PokemonMacCard(pokemon: pokemon)
                            .onTapGesture { onSelect(pokemon) }
                            .onAppear {
                                if pokemon.id == adapter.pokemons.last?.id {
                                    onLoadMore()
                                }
                            }
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if adapter.isLoading {
                ProgressView("Fetching Pok\u{00E9}mon...")
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .frame(minWidth: 520, minHeight: 480)
        .alert(item: $adapter.presentedError) { error in
            Alert(
                title: Text("Something went wrong"),
                message: Text(error.message),
                dismissButton: .default(Text("OK")) {
                    adapter.presentedError = nil
                }
            )
        }
    }
}

private struct PokemonMacCard: View {
    let pokemon: PokemonEntity

    var body: some View {
        VStack(spacing: 12) {
            PokemonImage(urlString: pokemon.imageURL)
                .frame(height: 120)
                .frame(maxWidth: .infinity)

            Text(pokemon.name.capitalized)
                .font(.headline.monospaced())
                .foregroundColor(.white)

            Text(String(format: "#%03d", pokemon.id))
                .font(.subheadline.monospaced())
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 8)
    }
}

private struct PokemonImage: View {
    let urlString: String

    var body: some View {
        if let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    placeholder
                case .empty:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
        }
    }
}

#endif
