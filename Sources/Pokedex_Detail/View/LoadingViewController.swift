import Shared_UI_Support
import UIKit

class LoadingViewController: UIViewController {

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let gradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        // Set up the gradient background
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [UIColor.systemTeal.cgColor, UIColor.systemPurple.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.addSublayer(gradientLayer)

        // Set up the activity indicator
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        // Center the activity indicator
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Start animating the activity indicator
        activityIndicator.startAnimating()

        // Add a pulsing animation to the gradient
        animateGradient()
    }

    private func animateGradient() {
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = [UIColor.systemTeal.cgColor, UIColor.systemPurple.cgColor]
        animation.toValue = [UIColor.systemPurple.cgColor, UIColor.systemTeal.cgColor]
        animation.duration = 2.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "gradientAnimation")
    }
}
#if DEBUG
import SwiftUI
#Preview {
    UIViewControllerPreview {
        LoadingViewController()
    }
}
#endif
