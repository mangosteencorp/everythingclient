import Shared_UI_Support
import UIKit

protocol RobotErrorViewControllerDelegate: AnyObject {
    func didTapTryAgain()
}

class RobotErrorViewController: UIViewController {
    weak var delegate: RobotErrorViewControllerDelegate?
    
    // MARK: - UI Components
    private let gradientLayer = CAGradientLayer()
    private let robotContainer = UIView()
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
            UIColor(red: 1.0, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.addSublayer(gradientLayer)
        
        // Stack View
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel, descriptionLabel, errorCodeLabel, tryAgainButton
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
            tryAgainButton.heightAnchor.constraint(equalToConstant: 50)
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
        antennaPath.move(to: CGPoint(x: containerWidth/2, y: -20))
        antennaPath.addLine(to: CGPoint(x: containerWidth/2 + 5, y: 0))
        antennaPath.addLine(to: CGPoint(x: containerWidth/2 - 5, y: 0))
        antennaPath.close()
        antennaLayer.path = antennaPath.cgPath

        // Exclamation
        let exclamationPath = UIBezierPath()
        exclamationPath.move(to: CGPoint(x: containerWidth/2, y: containerHeight - 40))
        exclamationPath.addLine(to: CGPoint(x: containerWidth/2 + 5, y: containerHeight - 20))
        exclamationPath.addLine(to: CGPoint(x: containerWidth/2 - 5, y: containerHeight - 20))
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
        bodyLayer.path = UIBezierPath(roundedRect: CGRect(x: 20, y: 100, width: 120, height: 120), cornerRadius: 20).cgPath
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
        arm.path = UIBezierPath(roundedRect: CGRect(x: position.x, y: position.y, width: 40, height: 80), cornerRadius: 8).cgPath
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
