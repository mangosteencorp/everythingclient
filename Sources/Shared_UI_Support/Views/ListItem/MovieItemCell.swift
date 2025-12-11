#if canImport(UIKit)
import Kingfisher
import SnapKit
import UIKit

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

@available(iOS 17, *)
#Preview {
    MovieItemCell()
}

#elseif canImport(AppKit)
import Kingfisher
import SnapKit
import AppKit

class RatingView: NSView {
    var label: NSTextField!

    override init(frame: CGRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        label = NSTextField(labelWithString: "N/A")
        label.textColor = ThemeService.primaryColor
        label.font = ThemeService.h2FontBold
        label.alignment = .center
        label.lineBreakMode = .byTruncatingTail

        addSubview(label)

        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() { super.layout(); needsDisplay = true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.setLineWidth(5.0)
        ThemeService.yellow.set()
        let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        let diameter = min(bounds.height, bounds.width)
        ctx.addArc(center: center, radius: diameter / 2, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
        ctx.fillPath()
    }

    func setRating(_ rating: Float) {
        if rating < 0.5 {
            label.stringValue = "N/A"
        } else {
            label.stringValue = String(format: "%.1f", rating)
        }
    }
}

public class MovieItemCell: NSCollectionViewItem {
    // Constants
    private let padding: CGFloat = 16.0

    // UI Components
    private let imageContainer: NSView = NSView()
    private let descContainer: NSView = NSView()
    private let posterView: NSImageView = NSImageView()
    private let dateLabel: NSTextField = NSTextField(labelWithString: "")
    private let titleLabel: NSTextField = NSTextField(labelWithString: "")
    private let separator: NSView = NSView()
    private let descLabel: NSTextField = NSTextField(labelWithString: "")
    private let ratingDisplay: RatingView = RatingView()
    private let favButton: FavButton = FavButton()

    // Delegate
    public weak var delegate: FavButtonDelegate?

    // Model
    private var item: ItemDisplayable? {
        didSet { updateContent() }
    }

    public override func loadView() {
        self.view = NSView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        posterView.image = nil
        dateLabel.stringValue = ""
        titleLabel.stringValue = ""
        descLabel.stringValue = ""
        ratingDisplay.setRating(0)
        delegate = nil
        favButton.delegate = nil
    }

    public func configure(with item: ItemDisplayable) {
        self.item = item
    }

    private func setupViews() {
        view.wantsLayer = true
        view.layer?.backgroundColor = ThemeService.midGrey.cgColor
        view.layer?.cornerRadius = 2
        view.layer?.borderColor = ThemeService.midGrey.cgColor
        view.layer?.borderWidth = 1

        imageContainer.wantsLayer = true
        imageContainer.layer?.backgroundColor = ThemeService.darkGrey.cgColor
        descContainer.wantsLayer = true
        descContainer.layer?.backgroundColor = NSColor.clear.cgColor

        posterView.imageScaling = .scaleAxesIndependently
        posterView.wantsLayer = true
        posterView.layer?.masksToBounds = true

        dateLabel.textColor = ThemeService.secondaryColor
        dateLabel.font = ThemeService.h2Font

        titleLabel.textColor = ThemeService.primaryColor
        titleLabel.font = ThemeService.h1Font
        titleLabel.maximumNumberOfLines = 1

        descLabel.textColor = ThemeService.secondaryColor
        descLabel.font = ThemeService.defaultFont
        descLabel.maximumNumberOfLines = 2

        separator.wantsLayer = true
        separator.layer?.backgroundColor = ThemeService.darkGrey.cgColor

        view.addSubview(imageContainer)
        view.addSubview(descContainer)
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
            make.left.equalTo(view.snp.left).offset(padding)
            make.width.equalTo(view.snp.width).multipliedBy(0.4).offset(-padding)
            make.top.equalTo(view.snp.top).offset(padding)
            make.bottom.equalTo(view.snp.bottom).offset(-padding)
        }

        posterView.snp.makeConstraints { make in
            make.edges.equalTo(imageContainer)
        }

        descContainer.snp.makeConstraints { make in
            make.left.equalTo(imageContainer.snp.right).offset(padding)
            make.right.equalTo(view.snp.right).offset(-padding)
            make.top.equalTo(view.snp.top).offset(padding)
            make.bottom.equalTo(view.snp.bottom).offset(-padding)
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

        dateLabel.stringValue = item.getReleaseDate() ?? ""
        titleLabel.stringValue = item.getTitle()
        descLabel.stringValue = item.getDescription()

        if let rating = item.getRating() {
            ratingDisplay.setRating(rating)
        }

        if let urlString = item.getImageURL(), let url = URL(string: urlString) {
            // Kingfisher for AppKit
            posterView.kf.setImage(with: url, options: [.transition(.fade(0.5))]) { [weak self] result in
                switch result {
                case .success(let value):
                    self?.updatePalette(withImage: value.image)
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
        }
    }

    private func updatePalette(withImage image: NSImage?) {
        view.layer?.backgroundColor = ThemeService.midGrey.cgColor
        dateLabel.textColor = ThemeService.black
        titleLabel.textColor = ThemeService.black
        descLabel.textColor = ThemeService.black

        guard let image = image else { return }

        DispatchQueue.global(qos: .background).async {
            let avgColor = image.averageColor() ?? .gray
            let textColor = avgColor.contrastingColor()

            DispatchQueue.main.async {
                self.view.layer?.backgroundColor = avgColor.cgColor
                self.dateLabel.textColor = textColor
                self.titleLabel.textColor = textColor
                self.descLabel.textColor = textColor
            }
        }
    }
}

#endif
