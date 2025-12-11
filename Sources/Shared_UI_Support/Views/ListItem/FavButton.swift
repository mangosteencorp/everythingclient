import SnapKit
import Kingfisher

public protocol FavButtonDelegate: AnyObject {
    func favButtonTapped(for item: ItemDisplayable)
}

#if canImport(UIKit)
import UIKit

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

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setupWith(item: ItemDisplayable) {
        self.item = item
        setNeedsLayout()
    }

    override func layoutSubviews() { super.layoutSubviews(); updateDisplay() }

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

#elseif canImport(AppKit)
import AppKit

class FavButton: NSView {
    var item: ItemDisplayable?
    var label: NSTextField!
    weak var delegate: FavButtonDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.lightGray.cgColor
        layer?.cornerRadius = 4
        layer?.masksToBounds = true

        label = NSTextField(labelWithString: "Favorite?")
        label.textColor = ThemeService.white
        label.font = ThemeService.h2FontBold
        label.alignment = .center
        label.lineBreakMode = .byTruncatingTail

        addSubview(label)

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
            make.center.equalToSuperview()
        }

        let click = NSClickGestureRecognizer(target: self, action: #selector(didClick))
        addGestureRecognizer(click)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setupWith(item: ItemDisplayable) {
        self.item = item
        needsLayout = true
    }

    override func layout() { super.layout(); updateDisplay() }

    @objc func didClick() {
        guard let item = item else { return }
        delegate?.favButtonTapped(for: item)
    }

    func updateDisplay(force: Bool? = nil) {
        guard let item = item else { return }
        if item.isFavorited() || force == true {
            layer?.backgroundColor = ThemeService.lightGrey.cgColor
            label.stringValue = "Favorite"
            label.textColor = ThemeService.darkGrey
        } else {
            layer?.backgroundColor = NSColor.orange.cgColor
            label.stringValue = "+ Favorite"
            label.textColor = .white
        }
    }
}
#endif
