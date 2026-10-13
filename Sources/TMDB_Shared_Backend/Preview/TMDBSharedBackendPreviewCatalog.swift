#if DEBUG
import SwiftUI

/// Every TMDB backend preview as a view of its own, so Xcode's canvas, the integration launcher and
/// the screenshot run all render the same thing. Sign-in state comes from
/// `PreviewAuthenticationService`, so nothing reaches TMDB.
public enum TMDBSharedBackendPreviewCatalog: String, CaseIterable {
    case signInButtonSignedOut
    case signInButtonSignedIn

    @MainActor @ViewBuilder
    public var view: some View {
        let authService = PreviewAuthenticationService(isAuthenticated: self == .signInButtonSignedIn)
        TMDBSignInButton(viewModel: AuthenticationViewModel(authService: authService))
            .padding()
    }
}
#endif
