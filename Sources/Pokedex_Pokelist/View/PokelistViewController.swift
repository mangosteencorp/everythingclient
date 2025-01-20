import UIKit

final class PokelistViewController: UIViewController {
    var presenter: PokelistPresenterProtocol?
    private var isLoading = false
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .black
        cv.register(PokemonCell.self, forCellWithReuseIdentifier: PokemonCell.reuseIdentifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
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
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

// MARK: - PokelistViewProtocol
extension PokelistViewController: PokelistViewProtocol {
    func showPokemons() {
        collectionView.reloadData()
    }
    
    func showError(_ error: Error) {
        // Implement error handling UI
        print("Error loading pokemons: \(error)")
    }
    
    func showLoading() {
        isLoading = true
    }
    
    func hideLoading() {
        isLoading = false
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension PokelistViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter?.getPokemons().count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokemonCell.reuseIdentifier, for: indexPath) as? PokemonCell,
              let pokemon = presenter?.getPokemons()[indexPath.item] else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: pokemon)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16 * 2
        let spacing: CGFloat = 8
        let maxCellWidth: CGFloat = 180
        
        let availableWidth = collectionView.bounds.width - padding
        let numberOfColumns = max(2, Int(availableWidth / maxCellWidth))
        let totalSpacing = CGFloat(numberOfColumns - 1) * spacing
        let cellWidth = min(maxCellWidth, (availableWidth - totalSpacing) / CGFloat(numberOfColumns))
        
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

// MARK: - UIScrollViewDelegate
extension PokelistViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = scrollView.frame.size.height
        
        if offsetY > contentHeight - screenHeight - 100 {
            presenter?.loadMorePokemons()
        }
    }
} 
