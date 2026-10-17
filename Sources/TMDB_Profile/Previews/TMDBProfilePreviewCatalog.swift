#if DEBUG
import RxSwift
import Shared_UI_Support
import SwiftUI
import Swinject
import TMDB_Shared_Backend

/// Every profile preview as a view of its own, so Xcode's canvas, the integration launcher and the
/// screenshot run all render the same thing. Nothing reaches TMDB: the profile is
/// `sampleProfileEntity` and sign-in state comes from `PreviewAuthenticationService`.
public enum TMDBProfilePreviewCatalog: String, CaseIterable {
    case page
    case signedIn
    case signedOut

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .page:
            ProfilePageVCView(container: Self.signedOutContainer, onNavigateToMovie: { _ in }, onNavigateToTVShow: { _ in })
        case .signedIn, .signedOut:
            UIViewControllerPreview { Self.profileController(isAuthenticated: self == .signedIn) }
        }
    }

    /// Just enough of the backend for `ProfileAssembly`; signed out, so nothing is fetched.
    @MainActor
    private static var signedOutContainer: Container {
        let container = Container()
        container.register(TMDBAPIService.self) { _ in TMDBAPIService(apiKey: "") }
        container.register(AuthRepository.self) { _ in DefaultAuthRepository() }
        container.register((any AuthenticationViewModelProtocol).self) { _ in
            MainActor.assumeIsolated {
                AuthenticationViewModel(authService: PreviewAuthenticationService(isAuthenticated: false))
            }
        }
        return container
    }

    @MainActor
    private static func profileController(isAuthenticated: Bool) -> UINavigationController {
        let viewModel = ProfileViewModel(
            getProfileUseCase: PreviewGetProfileUseCase(),
            authViewModel: AuthenticationViewModel(authService: PreviewAuthenticationService(isAuthenticated: isAuthenticated))
        )
        return UINavigationController(rootViewController: ProfileViewController(viewModel: viewModel))
    }
}

private struct PreviewGetProfileUseCase: GetProfileUseCaseProtocol {
    func execute() -> Single<ProfileEntity> { .just(sampleProfileEntity) }
}
#endif
