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
    /// The page as the profile tab shows it, in a `NavigationStack`: the account is in the navigation bar.
    case signedInPage

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .page:
            NavigationStack {
                ProfilePage(container: Self.signedOutContainer, onNavigateToMovie: { _ in }, onNavigateToTVShow: { _ in })
            }
        case .signedIn, .signedOut:
            UIViewControllerPreview { Self.profileController(isAuthenticated: self == .signedIn) }
        case .signedInPage:
            NavigationStack { ProfilePage(makeViewModel: { Self.viewModel() }) }
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
    static func viewModel(isAuthenticated: Bool = true, profile: ProfileEntity = sampleProfileEntity) -> ProfileViewModel {
        ProfileViewModel(
            getProfileUseCase: PreviewGetProfileUseCase(profile: profile),
            authViewModel: AuthenticationViewModel(authService: PreviewAuthenticationService(isAuthenticated: isAuthenticated))
        )
    }

    @MainActor
    private static func profileController(isAuthenticated: Bool) -> UINavigationController {
        UINavigationController(rootViewController: ProfileViewController(viewModel: viewModel(isAuthenticated: isAuthenticated)))
    }
}

private struct PreviewGetProfileUseCase: GetProfileUseCaseProtocol {
    let profile: ProfileEntity

    func execute() -> Single<ProfileEntity> { .just(profile) }
}
#endif
