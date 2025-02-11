import UIKit
import Kingfisher
import Pokedex_Shared_Backend
import Shared_UI_Support

class DetailDesign1ViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var pokemon: PokemonDetail?
    
    required init(pokemon: PokemonDetail) {
        self.pokemon = pokemon
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        // Configure Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Configure Content View
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Header
        let headerLabel = UILabel()
        headerLabel.text = "Pokémon Details"
        headerLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        
        // Pokémon Image
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        if let url = URL(string: pokemon?.imageURL ?? "") {
            imageView.kf.setImage(with: url)
        }
        
        // Name and Number
        let nameLabel = UILabel()
        nameLabel.text = pokemon?.name
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        
        let numberLabel = UILabel()
        numberLabel.text = "#\(String(format: "%03d", pokemon?.id ?? 0))"
        numberLabel.font = UIFont.systemFont(ofSize: 18)
        numberLabel.textColor = .secondaryLabel
        
        // Weight
        let weightText = String(format: "%.1f kg", Float(pokemon?.weight ?? 0) / 10.0)
        let weightView = createInfoBadge(title: weightText)
        
        // Abilities
        let abilitiesText = "Abilities: " + (pokemon?.abilities.map { $0.name }.joined(separator: " · ") ?? "")
        let abilitiesView = createInfoBadge(title: abilitiesText)
        
        // Stats Grid
        let statsView = createStatsGrid()
        
        // Moves
        let movesLabel = UILabel()
        movesLabel.text = "Moves"
        movesLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        let movesCollectionView = createMovesCollectionView()
        
        // Stack View
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel, imageView, hStack(items: [nameLabel, numberLabel]),
            hStack(items: [weightView, abilitiesView]), statsView, movesLabel, movesCollectionView
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.setCustomSpacing(40, after: imageView)
        
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            imageView.heightAnchor.constraint(equalToConstant: 150),
            weightView.heightAnchor.constraint(equalToConstant: 30),
            abilitiesView.heightAnchor.constraint(equalToConstant: 30),
            movesCollectionView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func createStatsGrid() -> UIView {
        let stats = pokemon?.stats.map { stat in
            (stat.name.capitalized, String(stat.baseStat))
        } ?? []
        
        let column1 = createStatColumn(stats: Array(stats.prefix(3)))
        let column2 = createStatColumn(stats: Array(stats.suffix(from: min(3, stats.count))))
        
        let stackView = UIStackView(arrangedSubviews: [column1, column2])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
        
        return container
    }
    
    private func createStatColumn(stats: [(String, String)]) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        
        for stat in stats {
            let titleLabel = UILabel()
            titleLabel.text = stat.0
            titleLabel.font = UIFont.systemFont(ofSize: 14)
            
            let valueLabel = UILabel()
            valueLabel.text = stat.1
            valueLabel.font = UIFont.systemFont(ofSize: 14)
            valueLabel.textColor = .secondaryLabel
            
            let statStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
            statStack.axis = .vertical
            statStack.spacing = 4
            
            stackView.addArrangedSubview(statStack)
        }
        
        return stackView
    }
    
    private func createMovesCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(MoveCell.self, forCellWithReuseIdentifier: "MoveCell")
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        
        return collectionView
    }
    
    private func hStack(items: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: items)
        stack.axis = .horizontal
        stack.spacing = 10
        return stack
    }
    
    private func createInfoBadge(title: String) -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.borderColor = UIColor.systemGray5.cgColor
        view.layer.borderWidth = 1
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 14)
        
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        return view
    }
}

extension DetailDesign1ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pokemon?.moves.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MoveCell", for: indexPath) as? MoveCell,
              let move = pokemon?.moves[indexPath.item] else {
            return UICollectionViewCell()
        }
        cell.configure(with: move.name)
        return cell
    }
}

class MoveCell: UICollectionViewCell {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        layer.cornerRadius = 14
        
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }
    
    func configure(with text: String) {
        label.text = text
    }
}

#if DEBUG
import SwiftUI
#Preview {
    UIViewControllerPreview {
        DetailDesign1ViewController(pokemon: PokemonDetail(
            id: 1,
            name: "Caterpie",
            imageURL: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/shiny/10.gif",
            weight: 290,
            speciesId: 1,
            moves: [
                PokemonDetail.Move(id: 1, moveId: 33, name: "Tackle"),
                PokemonDetail.Move(id: 2, moveId: 81, name: "String Shot"),
                PokemonDetail.Move(id: 3, moveId: 173, name: "Snore"),
                PokemonDetail.Move(id: 4, moveId: 450, name: "Bug Bite"),
                PokemonDetail.Move(id: 5, moveId: 527, name: "Electroweb")
            ],
            abilities: [
                PokemonDetail.Ability(abilityId: 19, name: "Shield Dust"),
                PokemonDetail.Ability(abilityId: 50, name: "Run Away")
            ],
            stats: [
                PokemonDetail.Stat(statId: 1, baseStat: 45, effort: 1, name: "HP"),
                PokemonDetail.Stat(statId: 2, baseStat: 30, effort: 0, name: "Attack"),
                PokemonDetail.Stat(statId: 3, baseStat: 35, effort: 0, name: "Defense"),
                PokemonDetail.Stat(statId: 4, baseStat: 20, effort: 0, name: "Sp. Atk"),
                PokemonDetail.Stat(statId: 5, baseStat: 20, effort: 0, name: "Sp. Def"),
                PokemonDetail.Stat(statId: 6, baseStat: 45, effort: 0, name: "Speed")
            ]
        ))
    }
}
#endif
