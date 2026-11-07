import SwiftUI
import UIKit

/// The UIKit profile page; `ProfilePage` puts it under the navigation bar.
public struct ProfilePageVCView: UIViewControllerRepresentable {
    public class Coordinator: NSObject {
        var onNavigateToMovie: (Int) -> Void
        var onNavigateToTVShow: (Int) -> Void

        init(onNavigateToMovie: @escaping (Int) -> Void, onNavigateToTVShow: @escaping (Int) -> Void) {
            self.onNavigateToMovie = onNavigateToMovie
            self.onNavigateToTVShow = onNavigateToTVShow
        }

        func navigateToMovie(_ id: Int) {
            onNavigateToMovie(id)
        }

        func navigateToTVShow(_ id: Int) {
            onNavigateToTVShow(id)
        }
    }

    let viewModel: ProfileViewModel
    var onNavigateToMovie: (Int) -> Void
    var onNavigateToTVShow: (Int) -> Void

    public func makeUIViewController(context: Context) -> ProfileViewController {
        let viewController = ProfileViewController(viewModel: viewModel)
        viewController.setCoordinator(makeCoordinator())
        return viewController
    }

    public func updateUIViewController(_ uiViewController: ProfileViewController, context: Context) {
        // No updates needed as the ViewController handles its own state
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(
            onNavigateToMovie: onNavigateToMovie,
            onNavigateToTVShow: onNavigateToTVShow
        )
    }
}

#if DEBUG
#Preview {
    TMDBProfilePreviewCatalog.page.view
}
#endif
