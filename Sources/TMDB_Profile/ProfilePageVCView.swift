import SwiftUI
import Swinject
import TMDB_Shared_Backend
import UIKit

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

    private let container: Container
    var onNavigateToMovie: (Int) -> Void
    var onNavigateToTVShow: (Int) -> Void

    public init(
        container: Container,

        onNavigateToMovie: @escaping (Int) -> Void,
        onNavigateToTVShow: @escaping (Int) -> Void
    ) {
        self.container = container
        self.onNavigateToMovie = onNavigateToMovie
        self.onNavigateToTVShow = onNavigateToTVShow
        TMDB_Profile.configure(container)
    }

    public func makeUIViewController(context: Context) -> ProfileViewController {
        guard let viewController = container.resolve(ProfileViewController.self) else {
            fatalError("Failed to resolve ProfileViewController")
        }
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
