import SwiftUI
import AuthenticationServices
import Foundation
import Combine
import Network



public struct LoginView: View {
    @StateObject private var userVM = UserViewModel(service: NetworkManager(), keychainM: KeychainManager())
    public init(){}
    public var body: some View {
        VStack {
            Text("login_title", bundle: Constants.bundle)
                .padding()
            Button("Log in") {
                Task {
                    try await userVM.LogIn()
                }
            }
            .disabled(userVM.isLoading)
            
            if userVM.isLoading {
                ProgressView()
            }
        }
        .onAppear {
            debugPrint("\(Constants.bundle.bundleIdentifier) having \(Constants.bundle.localizations)")
        }
        .alert(isPresented: $userVM.showAlert) {
            Alert(title: Text("login_error"), message: Text(userVM.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
