import SwiftUI

// MARK: - Simple Sign In Button View

@available(iOS 15.0, *)
public struct TMDBSignInButton: View {
    @ObservedObject private var viewModel: AuthenticationViewModel

    public init(viewModel: AuthenticationViewModel? = nil) {
        self.viewModel = viewModel ?? TMDB_Shared_Backend.container!.resolve(AuthenticationViewModel.self)!
    }

    public var body: some View {
        Button(action: {
            Task {
                await viewModel.signIn()
            }
        }) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text(viewModel.isAuthenticated ? "Sign Out of TMDB" : "Sign In to TMDB")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .disabled(viewModel.isLoading)
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK", role: .cancel) {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}
