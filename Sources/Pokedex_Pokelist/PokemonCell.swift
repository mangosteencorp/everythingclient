import UIKit
import Kingfisher
import Pokedex_Shared_Backend
class PokemonCell: UICollectionViewCell {
    static let reuseIdentifier = "PokemonCell"
    
    // MARK: - UI Elements
    private let spriteImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let idLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        contentView.addSubview(spriteImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(idLabel)
        
        NSLayoutConstraint.activate([
            spriteImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spriteImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -16),
            spriteImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),
            spriteImageView.heightAnchor.constraint(equalTo: spriteImageView.widthAnchor),
            
            idLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            idLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            nameLabel.topAnchor.constraint(equalTo: spriteImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configure Cell
    func configure(with pokemon: Pokemon) {
        nameLabel.text = pokemon.name
        idLabel.text = "#\(pokemon.id)"
        
        // Reset background color before loading a new image
        self.contentView.backgroundColor = .systemGray
        
        // Load image from URL using Kingfisher
        if let url = URL(string: pokemon.imageURL) {
            spriteImageView.kf.setImage(with: url) { result in
                switch result {
                case .success(let value):
                    let downloadedImage = value.image
                    // Compute average color from the downloaded image
                    let avgColor = downloadedImage.dominantColor ?? .blue
                    // Update the cell's background color on the main thread
                    
                    self.contentView.backgroundColor = avgColor
                    
                case .failure:
                    // If it fails, keep it gray or set any fallback color
                    self.contentView.backgroundColor = .systemOrange
                }
            }
        } else {
            // Invalid URL - fallback color
            self.contentView.backgroundColor = .systemGray
        }
    }
}
