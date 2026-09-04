#if canImport(AppKit) && !canImport(UIKit)
import AppKit
import Kingfisher
import Shared_UI_Support

/// The AppKit counterpart of `Pokedex_Pokelist.PokemonCell` — same layout (sprite, id badge,
/// name), same trick of tinting the tile with the sprite's average colour.
final class PokemonCollectionViewItem: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("PokemonCollectionViewItem")

    private let spriteView: NSImageView = {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.alignment = .center
        label.font = FontFamily.Pixelmix.regular.font(size: 14)
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let idLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.alignment = .right
        label.font = FontFamily.Pixelmix.regular.font(size: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // `NSCollectionViewItem` loads from a nib by default; this module builds its views in code.
    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        view.layer?.masksToBounds = true

        view.addSubview(spriteView)
        view.addSubview(nameLabel)
        view.addSubview(idLabel)

        NSLayoutConstraint.activate([
            spriteView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spriteView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16),
            spriteView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            spriteView.heightAnchor.constraint(equalTo: spriteView.widthAnchor),

            idLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            idLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            nameLabel.topAnchor.constraint(equalTo: spriteView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        spriteView.kf.cancelDownloadTask()
        spriteView.image = nil
        applyTint(.systemGray)
    }

    func configure(with pokemon: PokemonEntity) {
        nameLabel.stringValue = pokemon.name
        idLabel.stringValue = "#\(pokemon.id)"
        applyTint(.systemGray)

        guard let url = URL(string: pokemon.imageURL) else {
            applyTint(.systemGray)
            return
        }

        spriteView.kf.setImage(with: url) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(value):
                self.applyTint(value.image.averageColor() ?? .systemBlue)
            case .failure:
                self.applyTint(.systemOrange)
            }
        }
    }

    private func applyTint(_ color: NSColor) {
        view.layer?.backgroundColor = color.cgColor
        let labelColor = NSImage.contrastingLabelColor(on: color)
        nameLabel.textColor = labelColor
        idLabel.textColor = labelColor.withAlphaComponent(0.8)
    }
}
#endif
