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
            Text("Log in to your TMDB account")
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
        .alert(isPresented: $userVM.showAlert) {
            Alert(title: Text("Error"), message: Text(userVM.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
