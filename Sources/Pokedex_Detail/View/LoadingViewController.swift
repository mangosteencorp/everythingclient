import Shared_UI_Support
#if canImport(UIKit)
import UIKit

#elseif canImport(AppKit)
import AppKit

#endif

class LoadingViewController: PlatformViewController {
    #if canImport(UIKit)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    #elseif canImport(AppKit)
    private let activityIndicator: NSProgressIndicator = {
        let indicator = NSProgressIndicator()
        indicator.isIndeterminate = true
        indicator.style = .spinning
        indicator.controlSize = .large
        indicator.isDisplayedWhenStopped = false
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    #endif
    
    private let gradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        #if canImport(AppKit)
        view.wantsLayer = true
        #endif
        
        // Set up the gradient background
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [PlatformColor.systemTeal.cgColor, PlatformColor.systemPurple.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        #if canImport(UIKit)
        view.layer.addSublayer(gradientLayer)
        #elseif canImport(AppKit)
        view.layer?.addSublayer(gradientLayer)
        #endif

        // Set up the activity indicator
        #if canImport(UIKit)
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        #elseif canImport(AppKit)
        view.addSubview(activityIndicator)
        #endif
        
        // Center the activity indicator
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        // Start animating the activity indicator
        #if canImport(UIKit)
        activityIndicator.startAnimating()
        #elseif canImport(AppKit)
        activityIndicator.startAnimation(nil)
        #endif

        // Add a pulsing animation to the gradient
        animateGradient()
    }

    private func animateGradient() {
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = [PlatformColor.systemTeal.cgColor, PlatformColor.systemPurple.cgColor]
        animation.toValue = [PlatformColor.systemPurple.cgColor, PlatformColor.systemTeal.cgColor]
        animation.duration = 2.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "gradientAnimation")
    }
    
    #if canImport(UIKit)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    #elseif canImport(AppKit)
    override func viewDidLayout() {
        super.viewDidLayout()
        gradientLayer.frame = view.bounds
    }
    #endif
}

#if DEBUG
import SwiftUI

#Preview {
    #if canImport(UIKit)
    UIViewControllerPreview {
        LoadingViewController()
    }
    #elseif canImport(AppKit)
    NSViewControllerPreview {
        LoadingViewController()
    }
    #endif
}
#endif
