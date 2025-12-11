import Kingfisher
import Pokedex_Shared_Backend
import Shared_UI_Support

#if canImport(UIKit)
import UIKit

class PokemonCell: UICollectionViewCell {
    static let reuseIdentifier = "PokemonCell"

    // MARK: - UI Elements

    private let spriteImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = FontFamily.Pixelmix.regular.font(size: 14)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let idLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = FontFamily.Pixelmix.regular.font(size: 12)
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
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure Cell

    func configure(with pokemon: PokemonEntity) {
        nameLabel.text = pokemon.name
        idLabel.text = "#\(pokemon.id)"

        // Reset background color before loading a new image
        contentView.backgroundColor = .systemGray

        // Load image from URL using Kingfisher
        if let url = URL(string: pokemon.imageURL) {
            spriteImageView.kf.setImage(with: url) { result in
                switch result {
                case let .success(value):
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
            contentView.backgroundColor = .systemGray
        }
    }
}

#elseif canImport(AppKit)
import AppKit

final class PokemonCell: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("PokemonCell")

    private let spriteImageView: NSImageView = {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.alignment = .center
        label.font = FontFamily.Pixelmix.regular.font(size: 14)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let idLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.alignment = .right
        label.font = FontFamily.Pixelmix.regular.font(size: 12)
        label.textColor = NSColor.white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.wantsLayer = true
        view.layer?.cornerRadius = 14
        view.layer?.masksToBounds = true
        view.layer?.backgroundColor = NSColor.systemGray.cgColor

        [spriteImageView, nameLabel, idLabel].forEach { subview in
            view.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            spriteImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spriteImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16),
            spriteImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            spriteImageView.heightAnchor.constraint(equalTo: spriteImageView.widthAnchor),

            idLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            idLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            nameLabel.topAnchor.constraint(equalTo: spriteImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8),
        ])
    }

    func configure(with pokemon: PokemonEntity) {
        nameLabel.stringValue = pokemon.name.capitalized
        idLabel.stringValue = String(format: "#%03d", pokemon.id)
        view.layer?.backgroundColor = NSColor.systemGray.cgColor

        if let url = URL(string: pokemon.imageURL) {
            spriteImageView.kf.setImage(with: url) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(value):
                    let avgColor = value.image.dominantColor ?? NSColor.systemBlue
                    DispatchQueue.main.async {
                        self.view.layer?.backgroundColor = avgColor.cgColor
                    }
                case .failure:
                    DispatchQueue.main.async {
                        self.view.layer?.backgroundColor = NSColor.systemOrange.cgColor
                    }
                }
            }
        }
    }
}

#endif
