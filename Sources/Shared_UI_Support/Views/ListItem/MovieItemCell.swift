import SnapKit
import UIKit

// Generic model protocol to represent an item (e.g., movie, product)
public protocol ItemDisplayable {
    func getId() -> String?
    func getTitle() -> String
    func getDescription() -> String
    func getReleaseDate() -> String?
    func getRating() -> Float?
    func getImageURL() -> String?
    func isFavorited() -> Bool
    func setFavorited(_ favorited: Bool)
}

public class MovieItemCell: UICollectionViewCell {
    // Constants
    private let padding: CGFloat = 16.0
    private let imageWidthRatio: CGFloat = 0.4

    // UI Components
    private let imageContainer: UIView = UIView()
    private let descContainer: UIView = UIView()
    private let posterView: UIImageView = UIImageView()
    private let dateLabel: UILabel = UILabel()
    private let titleLabel: UILabel = UILabel()
    private let descLabel: UILabel = UILabel()
    private let ratingView: UILabel = UILabel() // Simplified rating display
    private let favoriteButton: UIButton = UIButton(type: .system)
    private let separator: UIView = UIView()

    // Model
    private var item: ItemDisplayable? {
        didSet { updateContent() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        posterView.image = nil
        dateLabel.text = ""
        titleLabel.text = ""
        descLabel.text = ""
        ratingView.text = ""
        favoriteButton.setTitle("+ Favorite", for: .normal)
        favoriteButton.backgroundColor = .orange
    }

    // Public method to configure the cell
    public func configure(with item: ItemDisplayable) {
        self.item = item
    }

    // Private setup methods
    private func setupViews() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 2
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.lightGray.cgColor

        imageContainer.backgroundColor = .lightGray
        descContainer.backgroundColor = .clear

        posterView.contentMode = .scaleAspectFill
        posterView.clipsToBounds = true

        dateLabel.textColor = .darkGray
        dateLabel.font = .systemFont(ofSize: 14)

        titleLabel.textColor = .black
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5

        descLabel.textColor = .darkGray
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.numberOfLines = 2

        separator.backgroundColor = .lightGray

        ratingView.textColor = .black
        ratingView.font = .boldSystemFont(ofSize: 16)
        ratingView.textAlignment = .center
        ratingView.layer.cornerRadius = 15
        ratingView.clipsToBounds = true
        ratingView.backgroundColor = .yellow

        favoriteButton.setTitleColor(.white, for: .normal)
        favoriteButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        favoriteButton.backgroundColor = .orange
        favoriteButton.layer.cornerRadius = 4
        favoriteButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)

        contentView.addSubview(imageContainer)
        contentView.addSubview(descContainer)
        imageContainer.addSubview(posterView)
        descContainer.addSubview(dateLabel)
        descContainer.addSubview(titleLabel)
        descContainer.addSubview(separator)
        descContainer.addSubview(descLabel)
        descContainer.addSubview(ratingView)
        descContainer.addSubview(favoriteButton)
    }

    private func setupConstraints() {
        imageContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(padding)
            make.width.equalToSuperview().multipliedBy(imageWidthRatio).inset(padding)
            make.top.equalToSuperview().offset(padding)
            make.bottom.equalToSuperview().inset(padding)
        }

        posterView.snp.makeConstraints { make in
            make.edges.equalTo(imageContainer)
        }

        descContainer.snp.makeConstraints { make in
            make.left.equalTo(imageContainer.snp.right).offset(padding)
            make.width.equalToSuperview().multipliedBy(1 - imageWidthRatio).inset(padding / 2)
            make.top.equalToSuperview().offset(padding)
            make.bottom.equalToSuperview().inset(padding)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom)
            make.width.equalToSuperview()
            make.height.equalTo(30)
        }

        separator.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(padding / 2)
            make.width.equalTo(100)
            make.height.equalTo(2)
        }

        descLabel.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom).offset(padding / 2)
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(60)
        }

        ratingView.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom)
            make.left.equalToSuperview()
            make.width.equalToSuperview().dividedBy(4)
            make.height.equalTo(30)
        }

        favoriteButton.snp.makeConstraints { make in
            make.left.equalTo(ratingView.snp.right).offset(padding)
            make.right.equalToSuperview().inset(padding)
            make.top.equalTo(descLabel.snp.bottom)
            make.height.equalTo(30)
        }
    }

    private func updateContent() {
        guard let item = item else { return }

        dateLabel.text = item.getReleaseDate()
        titleLabel.text = item.getTitle()
        descLabel.text = item.getDescription()
        ratingView.text = item.getRating().map { String(format: "%.1f", $0) } ?? "N/A"
//        ratingView.snp.updateConstraints { make in
//            make.width.equalTo(ratingView.text?.isEmpty ?? true ? 0 : 30)
//        }
        updateFavoriteButton()

        // Placeholder for image loading (replace with your image loading library, e.g., SDWebImage or AlamofireImage)
        if let urlString = item.getImageURL(), let url = URL(string: urlString) {
            // Example: Use URLSession or a library to load the image
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.posterView.image = image
                    }
                }
            }.resume()
        }
    }

    @objc private func toggleFavorite() {
        guard let item = item else { return }
        let currentFavorited = item.isFavorited()
        item.setFavorited(!currentFavorited)
        updateFavoriteButton()
        // Add your favorite toggle logic here (e.g., notify a delegate or update a state manager)
    }

    private func updateFavoriteButton() {
        let isFavorited = item?.isFavorited() ?? false
        favoriteButton.setTitle(isFavorited ? "Favorite" : "+ Favorite", for: .normal)
        favoriteButton.backgroundColor = isFavorited ? .lightGray : .orange
    }
}

@available(iOS 17, *)
#Preview {
    MovieItemCell()
}
