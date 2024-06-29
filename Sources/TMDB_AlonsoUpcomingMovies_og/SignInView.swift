import SwiftUI

public struct SignInView: UIViewControllerRepresentable {
    public init() {}
    public func makeUIViewController(context: Context) -> SignInViewController {
        let viewController = SignInViewController()
        let authService = AuthService()
        let viewModel = SignInViewModel(authService: authService)
        viewController.viewModel = viewModel
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: SignInViewController, context: Context) {
        // Update the view controller if needed
    }
}
