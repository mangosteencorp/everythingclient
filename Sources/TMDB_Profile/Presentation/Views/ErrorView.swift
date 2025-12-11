#if canImport(UIKit)
import UIKit

class ErrorView: UIView {
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Something went wrong"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Try Again", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .systemBackground

        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false

        [imageView, titleLabel, messageLabel, retryButton].forEach {
            containerStackView.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),

            imageView.heightAnchor.constraint(equalToConstant: 50),
            imageView.widthAnchor.constraint(equalToConstant: 50),

            retryButton.heightAnchor.constraint(equalToConstant: 44),
            retryButton.widthAnchor.constraint(equalToConstant: 120),
        ])
    }

    func configure(with error: Error, retryAction: @escaping () -> Void) {
        messageLabel.text = error.localizedDescription
        retryButton.addAction(UIAction { _ in retryAction() }, for: .touchUpInside)
    }
}

@available(iOS 17, *)
#Preview {
    ErrorView()
}
#elseif canImport(AppKit)
import AppKit

class ErrorView: NSView {
    private let containerStackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 16
        stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let imageView: NSImageView = {
        let imageView = NSImageView()
        if #available(macOS 11.0, *) {
            imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 40, weight: .bold)
            imageView.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)
        } else {
            imageView.image = NSImage(named: NSImage.cautionName)
        }
        if #available(macOS 10.14, *) {
            imageView.contentTintColor = .systemRed
        }
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Something went wrong")
        label.font = .boldSystemFont(ofSize: 20)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 16)
        if #available(macOS 10.14, *) {
            label.textColor = .secondaryLabelColor
        }
        label.alignment = .center
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let retryButton: NSButton = {
        let button = NSButton(title: "Try Again", target: nil, action: nil)
        button.font = .systemFont(ofSize: 16, weight: .semibold)
        button.bezelStyle = .rounded
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 8
        button.layer?.backgroundColor = NSColor.systemBlue.cgColor
        if #available(macOS 10.14, *) {
            button.contentTintColor = .white
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var retryAction: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        addSubview(containerStackView)

        [imageView, titleLabel, messageLabel, retryButton].forEach {
            containerStackView.addArrangedSubview($0)
        }

        retryButton.target = self
        retryButton.action = #selector(handleRetryButtonTap)

        NSLayoutConstraint.activate([
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),

            imageView.heightAnchor.constraint(equalToConstant: 50),
            imageView.widthAnchor.constraint(equalToConstant: 50),

            retryButton.heightAnchor.constraint(equalToConstant: 44),
            retryButton.widthAnchor.constraint(equalToConstant: 120),
        ])
    }

    func configure(with error: Error, retryAction: @escaping () -> Void) {
        messageLabel.stringValue = error.localizedDescription
        self.retryAction = retryAction
    }

    @objc private func handleRetryButtonTap() {
        retryAction?()
    }
}
#endif
