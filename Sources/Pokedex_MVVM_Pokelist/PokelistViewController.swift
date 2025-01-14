import UIKit

class ViewController: UIViewController {
    
    // Example: sample data
    let pokemons: [Pokemon] = [
        Pokemon(id: 1, name: "Bulbasaur", imageURL: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/101.png"),
        Pokemon(id: 2, name: "Ivysaur", imageURL: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/102.png"),
        Pokemon(id: 3, name: "Venusaur", imageURL: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/103.png")
        // Add more ...
    ]
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pokemons.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
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
    
    
    func collectionView(_ collectionView: UICollectionView,
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
@available(iOS 17.0, *)
#Preview {
    ViewController()
}
