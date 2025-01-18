import UIKit
import Pokedex_Shared_Backend
public class PokelistViewController: UIViewController {
    private let pokemonService: PokemonService
    private var pokemons: [Pokemon] = []
    private var isLoading = false
    private var currentOffset = 0
    private let itemsPerPage = 20
    
    public init(pokemonService: PokemonService) {
        self.pokemonService = pokemonService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .black
        // Register cell
        cv.register(PokemonCell.self, forCellWithReuseIdentifier: PokemonCell.reuseIdentifier)
        
        // Set delegates
        cv.dataSource = self
        cv.delegate = self
        
        return cv
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        loadMorePokemons()
    }
    
    private func loadMorePokemons() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                let newPokemons = try await pokemonService.fetchPokemons(
                    limit: itemsPerPage,
                    offset: currentOffset
                )
                
                await MainActor.run {
                    self.pokemons.append(contentsOf: newPokemons)
                    self.currentOffset += newPokemons.count
                    self.collectionView.reloadData()
                    self.isLoading = false
                }
            } catch {
                print("Error loading pokemons: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension PokelistViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pokemons.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PokemonCell.reuseIdentifier,
            for: indexPath) as? PokemonCell else {
            return UICollectionViewCell()
        }
        
        let pokemon = pokemons[indexPath.item]
        cell.configure(with: pokemon)
        
        return cell
    }
    
    
    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16 * 2 // Left and right padding
        let spacing: CGFloat = 8      // Minimum spacing between items
        let maxCellWidth: CGFloat = 180 // Maximum width for each cell
        
        let availableWidth = collectionView.bounds.width - padding
        
        // Calculate number of columns that can fit
        let numberOfColumns = max(2, Int(availableWidth / maxCellWidth))
        
        // Calculate actual cell width
        let totalSpacing = CGFloat(numberOfColumns - 1) * spacing
        let cellWidth = min(maxCellWidth, (availableWidth - totalSpacing) / CGFloat(numberOfColumns))
        
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

// MARK: - UIScrollViewDelegate
extension PokelistViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = scrollView.frame.size.height
        
        // Load more when user scrolls near the bottom
        if offsetY > contentHeight - screenHeight - 100 {
            loadMorePokemons()
        }
    }
}
@available(iOS 17.0, *)
#Preview {
    PokelistViewController(pokemonService: PokemonService.shared)
}
