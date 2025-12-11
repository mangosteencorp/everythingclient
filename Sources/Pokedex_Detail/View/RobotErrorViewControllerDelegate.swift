import Shared_UI_Support

protocol RobotErrorViewControllerDelegate: AnyObject {
    func didTapTryAgain()
}

#if canImport(UIKit)
import UIKit

final class RobotErrorViewController: UIViewController {
    weak var delegate: RobotErrorViewControllerDelegate?

    // MARK: - UI Components

    private let gradientLayer = CAGradientLayer()
    private let robotContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let antennaLayer = CAShapeLayer()
    private let bodyLayer = CAShapeLayer()
    private let exclamationLayer = CAShapeLayer()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.text = "OOPS! SOMETHING BROKE"
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        label.text = "Our robots are working hard to fix this"
        return label
    }()

    private let errorCodeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.8)
        label.text = "Error code: 404-B10B"
        return label
    }()

    private lazy var tryAgainButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 1.0, green: 0.33, blue: 0.33, alpha: 1.0)
        button.setTitle("TRY AGAIN", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleTryAgain), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createRobot()
        startAnimations()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        updateRobotPath()
    }

    // MARK: - Setup

    private func setupViews() {
        // Gradient Background
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.27, blue: 0.27, alpha: 1.0).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.addSublayer(gradientLayer)

        // Stack View
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel, descriptionLabel, errorCodeLabel, tryAgainButton,
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(robotContainer)
        view.addSubview(stackView)

        // Constraints
        NSLayoutConstraint.activate([
            robotContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            robotContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            robotContainer.widthAnchor.constraint(equalToConstant: 160),
            robotContainer.heightAnchor.constraint(equalToConstant: 200),

            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: robotContainer.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            tryAgainButton.widthAnchor.constraint(equalToConstant: 200),
            tryAgainButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    // MARK: - Robot Creation

    private func createRobot() {
        // Head
        let headLayer = CAShapeLayer()
        headLayer.path = UIBezierPath(roundedRect: CGRect(x: 40, y: 0, width: 80, height: 100), cornerRadius: 16).cgPath
        headLayer.fillColor = UIColor.lightGray.cgColor

        // Eyes
        let leftEye = createEye(at: CGPoint(x: 60, y: 40))
        let rightEye = createEye(at: CGPoint(x: 100, y: 40))

        // Body
        bodyLayer.fillColor = UIColor.gray.cgColor

        // Arms
        let leftArm = createArm(at: CGPoint(x: 0, y: 110))
        let rightArm = createArm(at: CGPoint(x: 120, y: 110))

        let antennaLight = createAntennaLight()

        // Inside createRobot() method
        let containerWidth = robotContainer.bounds.width
        let containerHeight = robotContainer.bounds.height

        // Antenna
        let antennaPath = UIBezierPath()
        antennaPath.move(to: CGPoint(x: containerWidth / 2, y: -20))
        antennaPath.addLine(to: CGPoint(x: containerWidth / 2 + 5, y: 0))
        antennaPath.addLine(to: CGPoint(x: containerWidth / 2 - 5, y: 0))
        antennaPath.close()
        antennaLayer.path = antennaPath.cgPath

        // Exclamation
        let exclamationPath = UIBezierPath()
        exclamationPath.move(to: CGPoint(x: containerWidth / 2, y: containerHeight - 40))
        exclamationPath.addLine(to: CGPoint(x: containerWidth / 2 + 5, y: containerHeight - 20))
        exclamationPath.addLine(to: CGPoint(x: containerWidth / 2 - 5, y: containerHeight - 20))
        exclamationPath.close()
        exclamationLayer.path = exclamationPath.cgPath

        exclamationLayer.fillColor = UIColor.systemRed.cgColor

        robotContainer.layer.addSublayer(antennaLayer)
        robotContainer.layer.addSublayer(antennaLight)
        robotContainer.layer.addSublayer(headLayer)
        robotContainer.layer.addSublayer(leftEye)
        robotContainer.layer.addSublayer(rightEye)
        robotContainer.layer.addSublayer(bodyLayer)
        robotContainer.layer.addSublayer(leftArm)
        robotContainer.layer.addSublayer(rightArm)
        robotContainer.layer.addSublayer(exclamationLayer)
    }

    private func updateRobotPath() {
        bodyLayer.path = UIBezierPath(roundedRect: CGRect(x: 20, y: 100, width: 120, height: 120), cornerRadius: 20)
            .cgPath
    }

    // MARK: - Animation

    private func startAnimations() {
        let bodyAnimation = CABasicAnimation(keyPath: "position.y")
        bodyAnimation.fromValue = robotContainer.center.y - 5
        bodyAnimation.toValue = robotContainer.center.y + 5
        bodyAnimation.duration = 1.5
        bodyAnimation.autoreverses = true
        bodyAnimation.repeatCount = .infinity
        robotContainer.layer.add(bodyAnimation, forKey: "bodyBounce")

        let antennaAnimation = CABasicAnimation(keyPath: "position.y")
        antennaAnimation.fromValue = antennaLayer.position.y - 2
        antennaAnimation.toValue = antennaLayer.position.y + 2
        antennaAnimation.duration = 0.8
        antennaAnimation.autoreverses = true
        antennaAnimation.repeatCount = .infinity
        antennaLayer.add(antennaAnimation, forKey: "antennaBounce")
    }

    // MARK: - Helper Methods

    private func createEye(at position: CGPoint) -> CAShapeLayer {
        let eye = CAShapeLayer()
        eye.path = UIBezierPath(ovalIn: CGRect(x: position.x, y: position.y, width: 20, height: 20)).cgPath
        eye.fillColor = UIColor.black.cgColor
        return eye
    }

    private func createArm(at position: CGPoint) -> CAShapeLayer {
        let arm = CAShapeLayer()
        arm.path = UIBezierPath(
            roundedRect: CGRect(x: position.x, y: position.y, width: 40, height: 80),
            cornerRadius: 8
        ).cgPath
        arm.fillColor = UIColor.darkGray.cgColor
        return arm
    }

    private func createAntennaLight() -> CALayer {
        let light = CALayer()
        light.backgroundColor = UIColor.systemRed.cgColor
        light.frame = CGRect(x: 78, y: -10, width: 4, height: 4)
        light.cornerRadius = 2
        return light
    }

    // MARK: - Action

    @objc private func handleTryAgain() {
        delegate?.didTapTryAgain()
        dismiss(animated: true)
    }
}

#if DEBUG
import SwiftUI

#Preview {
    UIViewControllerPreview {
        RobotErrorViewController()
    }
}
#endif

#elseif canImport(AppKit)
import AppKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class RobotErrorViewController: NSViewController {
    weak var delegate: RobotErrorViewControllerDelegate?

    private let gradientLayer = CAGradientLayer()
    private let glassCard: NSVisualEffectView = {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .withinWindow
        view.state = .active
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.cornerRadius = 32
        view.layer?.masksToBounds = true
        return view
    }()

    private let iconImageView: NSImageView = {
        let imageView = NSImageView()
        if #available(macOS 11.0, *) {
            imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 80, weight: .semibold)
            imageView.image = NSImage(systemSymbolName: "gearshape.2.fill", accessibilityDescription: "Robot issue")
        } else {
            imageView.image = NSImage(named: NSImage.cautionName)
        }
        imageView.contentTintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.wantsLayer = true
        imageView.layer?.shadowColor = NSColor.black.cgColor
        imageView.layer?.shadowRadius = 12
        imageView.layer?.shadowOpacity = 0.3
        imageView.layer?.shadowOffset = .zero
        return imageView
    }()

    private let titleLabel = RobotErrorViewController.makeLabel(
        text: "SYSTEM GLITCH DETECTED",
        font: .systemFont(ofSize: 24, weight: .bold),
        alpha: 0.95
    )

    private let descriptionLabel = RobotErrorViewController.makeLabel(
        text: "Our maintenance bots are recalibrating the servos.",
        font: .systemFont(ofSize: 15, weight: .medium),
        alpha: 0.85
    )

    private let errorCodeLabel = RobotErrorViewController.makeLabel(
        text: "Incident #A1-BOT-404",
        font: .monospacedSystemFont(ofSize: 13, weight: .regular),
        alpha: 0.75
    )

    private lazy var tryAgainButton: NSButton = {
        let button = NSButton(title: "RUN DIAGNOSTICS", target: self, action: #selector(handleTryAgain))
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.font = .systemFont(ofSize: 16, weight: .semibold)
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.systemPink.cgColor
        button.layer?.cornerRadius = 24
        button.contentTintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var pulseLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        layer.cornerRadius = 60
        return layer
    }()

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        startAnimations()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        gradientLayer.frame = view.bounds
    }

    private func setupView() {
        view.wantsLayer = true
        view.layer?.masksToBounds = true

        gradientLayer.colors = [
            NSColor.systemPink.cgColor,
            NSColor.systemRed.cgColor,
            NSColor.black.cgColor,
        ]
        gradientLayer.locations = [0.0, 0.45, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer?.addSublayer(gradientLayer)

        view.addSubview(glassCard)

        let stackView = NSStackView(views: [iconImageView, titleLabel, descriptionLabel, errorCodeLabel, tryAgainButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 14
        stackView.setHuggingPriority(.required, for: .horizontal)
        glassCard.addSubview(stackView)

        iconImageView.layer?.insertSublayer(pulseLayer, at: 0)

        NSLayoutConstraint.activate([
            glassCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            glassCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            glassCard.widthAnchor.constraint(lessThanOrEqualToConstant: 460),
            glassCard.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            glassCard.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            stackView.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -32),
            stackView.bottomAnchor.constraint(equalTo: glassCard.bottomAnchor, constant: -32),

            iconImageView.widthAnchor.constraint(equalToConstant: 120),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            tryAgainButton.widthAnchor.constraint(equalToConstant: 220),
            tryAgainButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func startAnimations() {
        view.layoutSubtreeIfNeeded()
        let diameter = iconImageView.bounds.width + 40
        pulseLayer.frame = CGRect(
            x: (iconImageView.bounds.width - diameter) / 2,
            y: (iconImageView.bounds.height - diameter) / 2,
            width: diameter,
            height: diameter
        )
        pulseLayer.cornerRadius = diameter / 2

        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.fromValue = 0.95
        pulseAnimation.toValue = 1.05
        pulseAnimation.duration = 1.8
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        iconImageView.layer?.add(pulseAnimation, forKey: "pulse")

        let glowAnimation = CABasicAnimation(keyPath: "shadowRadius")
        glowAnimation.fromValue = 8
        glowAnimation.toValue = 18
        glowAnimation.duration = 2.0
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity
        iconImageView.layer?.add(glowAnimation, forKey: "glow")
    }

    @objc private func handleTryAgain() {
        delegate?.didTapTryAgain()
        dismiss(self)
    }

    private static func makeLabel(text: String, font: NSFont, alpha: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = NSColor.white.withAlphaComponent(alpha)
        label.alignment = .center
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 2
        return label
    }
}

#if DEBUG && canImport(SwiftUI)
#Preview {
    NSViewControllerPreview {
        RobotErrorViewController()
    }
}
#endif

#endif
