import UIKit
import Kingfisher
import Pokedex_Shared_Backend
class PokemonContentLoadedDetailViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 152/255, green: 251/255, blue: 152/255, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Caterpie #010"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let spriteImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let statsCard: UIView = createCard()
    private let abilitiesCard: UIView = createCard()
    private let movesCard: UIView = createCard()
    
    private let statsLabel = createSectionLabel(text: "Base Stats")
    private let abilitiesLabel = createSectionLabel(text: "Abilities")
    private let movesLabel = createSectionLabel(text: "Moves")
    
    private let statsStackView: UIStackView = createStackView()
    private let abilitiesStackView: UIStackView = createStackView()
    private let movesStackView: UIStackView = createStackView()
    
    private let pokemon: PokemonDetailModel
    
    init(pokemon: PokemonDetailModel) {
        self.pokemon = pokemon
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadSprite()
        setupContent()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [headerView, statsCard, abilitiesCard, movesCard].forEach { contentView.addSubview($0) }
        [nameLabel, spriteImageView].forEach { headerView.addSubview($0) }
        
        setupCardContent(statsCard, label: statsLabel, stackView: statsStackView)
        setupCardContent(abilitiesCard, label: abilitiesLabel, stackView: abilitiesStackView)
        setupCardContent(movesCard, label: movesLabel, stackView: movesStackView)
        
        setupConstraints()
    }
    
    private func setupCardContent(_ card: UIView, label: UILabel, stackView: UIStackView) {
        card.addSubview(label)
        card.addSubview(stackView)
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
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),
            
            nameLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            spriteImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            spriteImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            spriteImageView.widthAnchor.constraint(equalToConstant: 100),
            spriteImageView.heightAnchor.constraint(equalToConstant: 100),
        ])
        
        setupCardConstraints(statsCard, topAnchor: headerView.bottomAnchor)
        setupCardConstraints(abilitiesCard, topAnchor: statsCard.bottomAnchor)
        setupCardConstraints(movesCard, topAnchor: abilitiesCard.bottomAnchor)
        movesCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true
        
        [statsCard, abilitiesCard, movesCard].forEach { card in
            if let label = card.subviews.first(where: { $0 is UILabel }) as? UILabel,
               let stackView = card.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
                setupInnerCardConstraints(card: card, label: label, stackView: stackView)
            }
        }
    }
    
    private func setupCardConstraints(_ card: UIView, topAnchor: NSLayoutYAxisAnchor) {
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupInnerCardConstraints(card: UIView, label: UILabel, stackView: UIStackView) {
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            
            stackView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 15),
            stackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
    }
    
    private func loadSprite() {
        if let url = URL(string: pokemon.imageURL) {
            spriteImageView.kf.setImage(with: url)
        }
    }
    
    private func setupContent() {
        nameLabel.text = "\(pokemon.name) #\(String(format: "%03d", pokemon.id))"
        
        setupStats()
        setupAbilities()
        setupMoves()
    }
    
    private func setupStats() {
        let statsMap = [
            "hp": ("HP", UIColor(red: 255/255, green: 89/255, blue: 89/255, alpha: 1)),
            "attack": ("ATK", UIColor(red: 245/255, green: 172/255, blue: 120/255, alpha: 1)),
            "defense": ("DEF", UIColor(red: 250/255, green: 224/255, blue: 120/255, alpha: 1)),
            "speed": ("SPD", UIColor(red: 250/255, green: 146/255, blue: 178/255, alpha: 1))
        ]
        
        pokemon.stats
            .filter { stat in statsMap.keys.contains(stat.name) }
            .forEach { stat in
                if let (displayName, color) = statsMap[stat.name] {
                    statsStackView.addArrangedSubview(
                        createStatBar(name: displayName, value: stat.baseStat, color: color)
                    )
                }
            }
    }
    
    private func setupAbilities() {
        pokemon.abilities.forEach { ability in
            let abilityLabel = UILabel()
            abilityLabel.text = ability.name.capitalized
            abilityLabel.font = .systemFont(ofSize: 14)
            abilitiesStackView.addArrangedSubview(abilityLabel)
        }
    }
    
    private func setupMoves() {
        pokemon.moves.prefix(4).forEach { move in
            let moveLabel = UILabel()
            moveLabel.text = move.name.capitalized
            moveLabel.font = .systemFont(ofSize: 14)
            movesStackView.addArrangedSubview(moveLabel)
        }
    }
    
    private func createStatBar(name: String, value: Int, color: UIColor) -> UIView {
        let containerView = UIView()
        containerView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let barBackground = UIView()
        barBackground.backgroundColor = .systemGray6
        barBackground.layer.cornerRadius = 5
        barBackground.translatesAutoresizingMaskIntoConstraints = false
        
        let barFill = UIView()
        barFill.backgroundColor = color
        barFill.layer.cornerRadius = 5
        barFill.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = "\(value)"
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [nameLabel, barBackground, valueLabel].forEach { containerView.addSubview($0) }
        barBackground.addSubview(barFill)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 40),
            
            barBackground.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 20),
            barBackground.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            barBackground.widthAnchor.constraint(equalToConstant: 200),
            barBackground.heightAnchor.constraint(equalToConstant: 15),
            
            barFill.leadingAnchor.constraint(equalTo: barBackground.leadingAnchor),
            barFill.topAnchor.constraint(equalTo: barBackground.topAnchor),
            barFill.bottomAnchor.constraint(equalTo: barBackground.bottomAnchor),
            barFill.widthAnchor.constraint(equalTo: barBackground.widthAnchor, multiplier: CGFloat(value) / 100),
            
            valueLabel.leadingAnchor.constraint(equalTo: barBackground.trailingAnchor, constant: 10),
            valueLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }
    
    private static func createCard() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    private static func createSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private static func createStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
}
#if DEBUG
import SwiftUI
#Preview {
    UIViewControllerPreview {
        let pokemon = PokemonDetail(
            id: 10,
            name: "Caterpie",
            imageURL: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/shiny/10.gif",
            weight: 29,
            speciesId: 10,
            moves: [
                .init(id: 1, moveId: 1, name: "Tackle"),
                .init(id: 2, moveId: 2, name: "String Shot"),
                .init(id: 3, moveId: 3, name: "Bug Bite"),
                .init(id: 4, moveId: 4, name: "Electroweb")
            ],
            abilities: [
                .init(abilityId: 1, name: "Shield Dust"),
                .init(abilityId: 2, name: "Run Away")
            ],
            stats: [
                .init(statId: 1, baseStat: 45, effort: 1, name: "hp"),
                .init(statId: 2, baseStat: 30, effort: 0, name: "attack"),
                .init(statId: 3, baseStat: 35, effort: 0, name: "defense"),
                .init(statId: 6, baseStat: 45, effort: 0, name: "speed")
            ]
        )
        let navVC = UINavigationController(rootViewController: UIViewController())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            navVC.pushViewController(PokemonContentLoadedDetailViewController(pokemon: pokemon), animated: false)
        })
        return navVC
    }
}
#endif

