import Kingfisher
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

class RatingView: UIView {
    var label: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        label = UILabel()
        label.textColor = ThemeService.primaryColor
        label.text = "N/A"
        label.font = ThemeService.h2FontBold
        label.textAlignment = .center

        addSubview(label)

        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            context.setLineWidth(5.0)
            ThemeService.yellow.set()
            let center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
            let diameter = min(rect.height, rect.width)
            context.addArc(center: center, radius: diameter / 2, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
            context.fillPath()
        }
    }

    func setRating(_ rating: Float) {
        if rating < 0.5 {
            label.text = "N/A"
        } else {
            label.text = String(format: "%.1f", rating)
        }
    }
}

public protocol FavButtonDelegate: AnyObject {
    func favButtonTapped(for item: ItemDisplayable)
}

class FavButton: UIView {
    var item: ItemDisplayable?
    var label: UILabel!
    weak var delegate: FavButtonDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .lightGray
        layer.cornerRadius = 4
        clipsToBounds = true

        label = UILabel()
        label.textColor = ThemeService.white
        label.font = ThemeService.h2FontBold
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        label.text = "Favorite?"

        addSubview(label)

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
            make.center.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapGesture))
        addGestureRecognizer(tap)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupWith(item: ItemDisplayable) {
        self.item = item
        setNeedsLayout()
    }

    override func layoutSubviews() {
        updateDisplay()
    }

    @objc func didTapGesture() {
        guard let item = item else { return }
        delegate?.favButtonTapped(for: item)
    }

    func updateDisplay(force: Bool? = nil) {
        guard let item = item else { return }
        if item.isFavorited() || force == true {
            backgroundColor = ThemeService.lightGrey
            label.text = "Favorite"
            label.textColor = ThemeService.darkGrey
        } else {
            backgroundColor = .orange
            label.text = "+ Favorite"
            label.textColor = .white
        }
    }
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
    private let separator: UIView = UIView()
    private let descLabel: UILabel = UILabel()
    private let ratingDisplay: RatingView = RatingView()
    private let favButton: FavButton = FavButton()

    // Delegate
    public weak var delegate: FavButtonDelegate?

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
        ratingDisplay.setRating(0)
        delegate = nil
        favButton.delegate = nil
    }

    // Public method to configure the cell
    public func configure(with item: ItemDisplayable) {
        self.item = item
    }

    // Private setup methods
    private func setupViews() {
        contentView.backgroundColor = ThemeService.midGrey
        contentView.layer.cornerRadius = 2
        contentView.layer.borderColor = ThemeService.midGrey.cgColor
        contentView.layer.borderWidth = 1

        imageContainer.backgroundColor = ThemeService.darkGrey
        descContainer.backgroundColor = .clear

        posterView.contentMode = .scaleAspectFill
        posterView.clipsToBounds = true

        dateLabel.textColor = ThemeService.secondaryColor
        dateLabel.font = ThemeService.h2Font

        titleLabel.textColor = ThemeService.primaryColor
        titleLabel.font = ThemeService.h1Font
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5

        descLabel.textColor = ThemeService.secondaryColor
        descLabel.font = ThemeService.defaultFont
        descLabel.numberOfLines = 2

        separator.backgroundColor = ThemeService.darkGrey

        contentView.addSubview(imageContainer)
        contentView.addSubview(descContainer)
        imageContainer.addSubview(posterView)
        descContainer.addSubview(dateLabel)
        descContainer.addSubview(titleLabel)
        descContainer.addSubview(separator)
        descContainer.addSubview(descLabel)
        descContainer.addSubview(ratingDisplay)
        descContainer.addSubview(favButton)
    }

    private func setupConstraints() {
        imageContainer.snp.makeConstraints { make in
            make.left.equalTo(contentView.snp.left).offset(padding)
            make.width.equalTo(contentView.snp.width).multipliedBy(0.4).offset(-padding)
            make.top.equalTo(contentView.snp.top).offset(padding)
            make.bottom.equalTo(contentView.snp.bottom).offset(-padding)
        }

        posterView.snp.makeConstraints { make in
            make.edges.equalTo(imageContainer)
        }

        descContainer.snp.makeConstraints { make in
            make.left.equalTo(imageContainer.snp.right).offset(padding)
            make.right.equalTo(contentView.snp.right).offset(-padding)
            make.top.equalTo(contentView.snp.top).offset(padding)
            make.bottom.equalTo(contentView.snp.bottom).offset(-padding)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(descContainer.snp.top)
            make.left.equalTo(descContainer.snp.left)
            make.right.equalTo(descContainer.snp.right)
            make.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom)
            make.left.equalTo(descContainer.snp.left)
            make.right.equalTo(descContainer.snp.right)
            make.height.equalTo(30)
        }

        separator.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(padding / 2)
            make.left.equalTo(descContainer.snp.left)
            make.width.equalTo(100)
            make.height.equalTo(2)
        }

        descLabel.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom).offset(padding / 2)
            make.left.equalTo(descContainer.snp.left)
            make.right.equalTo(descContainer.snp.right)
            make.bottom.lessThanOrEqualTo(ratingDisplay.snp.top).offset(-padding)
        }

        ratingDisplay.snp.makeConstraints { make in
            make.bottom.equalTo(descContainer.snp.bottom).offset(-padding)
            make.left.equalTo(descContainer.snp.left)
            make.width.equalTo(60)
            make.height.equalTo(30)
        }

        favButton.snp.makeConstraints { make in
            make.bottom.equalTo(descContainer.snp.bottom).offset(-padding)
            make.right.equalTo(descContainer.snp.right)
            make.width.equalTo(100)
            make.height.equalTo(30)
        }
    }

    private func updateContent() {
        guard let item = item else { return }

        favButton.setupWith(item: item)
        favButton.delegate = delegate

        dateLabel.text = item.getReleaseDate()
        titleLabel.text = item.getTitle()
        descLabel.text = item.getDescription()

        if let rating = item.getRating() {
            ratingDisplay.setRating(rating)
        }

        if let urlString = item.getImageURL(), let url = URL(string: urlString) {
            posterView.kf.setImage(with: url, placeholder: nil, options: [.transition(.fade(0.5))]) { [weak self] result in
                switch result {
                case .success(let value):
                    self?.updatePalette(withImage: value.image)
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
        }
    }

    private func updatePalette(withImage image: UIImage?) {
        contentView.backgroundColor = ThemeService.midGrey
        dateLabel.textColor = ThemeService.black
        titleLabel.textColor = ThemeService.black
        descLabel.textColor = ThemeService.black

        guard let image = image else { return }

        DispatchQueue.global(qos: .background).async {
            let scaledImage = image.kf.resize(to: CGSize(width: 50, height: 50))
            let avgColor = scaledImage.averageColor() ?? .gray
            let textColor = avgColor.contrastingColor()

            DispatchQueue.main.async {
                self.contentView.backgroundColor = avgColor
                self.dateLabel.textColor = textColor
                self.titleLabel.textColor = textColor
                self.descLabel.textColor = textColor
            }
        }
    }
}

// MARK: - Theme Service

public class ThemeService: NSObject {
    public static let padding = 20
    public static let cellsHeight = 222
    public static let fontFamily = "HelveticaNeue"

    public static let h1Font = UIFont(name: "\(fontFamily)-Bold", size: 22)
    public static let h2FontBold = UIFont(name: "\(fontFamily)-Bold", size: 16)
    public static let h2Font = UIFont(name: "\(fontFamily)-Light", size: 16)
    public static let h3Font = UIFont(name: fontFamily, size: 12)
    public static let defaultFont = UIFont(name: fontFamily, size: 14)

    public static let lightGrey = UIColor(red: 235, green: 235, blue: 235)
    public static let midGrey = UIColor(red: 200, green: 200, blue: 200)
    public static let darkGrey = UIColor(red: 130, green: 130, blue: 130)
    public static let white = UIColor.white
    public static let yellow = UIColor(red: 250, green: 200, blue: 50)
    public static let black = UIColor(red: 40, green: 40, blue: 40)

    public static let primaryColor = black
    public static let secondaryColor = darkGrey
}

extension UIImage {
    func averageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                    y: inputImage.extent.origin.y,
                                    z: inputImage.extent.size.width,
                                    w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: inputImage,
                                                 kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255,
                       green: CGFloat(bitmap[1]) / 255,
                       blue: CGFloat(bitmap[2]) / 255,
                       alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red) / 255
        let newGreen = CGFloat(green) / 255
        let newBlue = CGFloat(blue) / 255
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }

    func contrastingColor() -> UIColor {
        guard let components = cgColor.components else { return .white }
        let brightness: CGFloat
        if components.count >= 3 {
            brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        } else {
            brightness = ((components[0] * 299) + (components[0] * 587) + (components[0] * 114)) / 1000
        }
        return brightness > 0.5 ? .black : .white
    }
}

@available(iOS 17, *)
#Preview {
    MovieItemCell()
}
