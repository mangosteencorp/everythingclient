import TMDB_Shared_Backend
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI
#if canImport(UIKit)
class UnauthorizedView: UIView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.crop.circle.badge.exclamationmark")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign in to access your profile"
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign In with TMDB", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
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

        [imageView, titleLabel, signInButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            // Image view constraints
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -60),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),

            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            // Sign in button constraints
            signInButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            signInButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            signInButton.widthAnchor.constraint(equalToConstant: 200),
            signInButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    func setSignInAction(_ action: @escaping () -> Void) {
        signInButton.addAction(UIAction { _ in action() }, for: .touchUpInside)
    }
}

@available(iOS 17, *)
#Preview {
    UnauthorizedView()
}
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
class UnauthorizedView: NSView {
    private let imageView: NSImageView = {
        let imageView = NSImageView()
        imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 80, weight: .regular)
        imageView.image = NSImage(systemSymbolName: "person.crop.circle.badge.exclamationmark", accessibilityDescription: nil)
        imageView.contentTintColor = .gray
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
    }()

    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Sign in to access your profile")
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.alignment = .center
        label.textColor = .labelColor
        return label
    }()

    private let signInButton: NSButton = {
        let button = NSButton(title: "Sign In with TMDB", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.contentTintColor = .white
        button.wantsLayer = true
        button.layer?.cornerRadius = 12
        button.layer?.backgroundColor = NSColor.systemBlue.cgColor
        return button
    }()

    private var signInAction: (() -> Void)?

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

        [imageView, titleLabel, signInButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        signInButton.target = self
        signInButton.action = #selector(handleSignInTap)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -60),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            signInButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            signInButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            signInButton.widthAnchor.constraint(equalToConstant: 200),
            signInButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    func setSignInAction(_ action: @escaping () -> Void) {
        signInAction = action
    }

    @objc private func handleSignInTap() {
        signInAction?()
    }
}
#endif
