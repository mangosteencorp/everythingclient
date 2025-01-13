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
        
        let columns: CGFloat = 2
        let spacing: CGFloat = 8
        let totalSpacing = (columns - 1) * spacing
        let availableWidth = collectionView.bounds.width
            - totalSpacing
            - collectionView.contentInset.left
            - collectionView.contentInset.right
        let cellWidth = floor(availableWidth / columns)
        
        return CGSize(width: cellWidth, height: cellWidth)
    }
}
@available(iOS 17.0, *)
#Preview {
    ViewController()
}
