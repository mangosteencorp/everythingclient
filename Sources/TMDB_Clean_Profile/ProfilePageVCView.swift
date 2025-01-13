import SwiftUI
import UIKit
import Swinject

public struct ProfilePageVCView: UIViewControllerRepresentable {
    private let container: Container
    
    public init(container: Container) {
        self.container = container
        TMDB_Clean_Profile.configure(container)
    }
    
    public func makeUIViewController(context: Context) -> ProfileViewController {
        guard let viewController = container.resolve(ProfileViewController.self) else {
            fatalError("Failed to resolve ProfileViewController")
        }
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: ProfileViewController, context: Context) {
        // No updates needed as the ViewController handles its own state
    }
}

#if DEBUG
struct ProfilePageVCView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePageVCView(container: Container())
    }
}
#endif
