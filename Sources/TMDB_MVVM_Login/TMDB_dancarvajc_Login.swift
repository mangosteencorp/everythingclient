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
            Button(action: {
                Task {
                    try await userVM.LogIn()
                }
            }, label: {
                Text("login_btn_login", bundle: Bundle.module)
            })
            .disabled(userVM.isLoading)
            
            if userVM.isLoading {
                ProgressView()
            }
        }
        .alert(isPresented: $userVM.showAlert) {
            Alert(
                title: Text("login_error", bundle: Bundle.module),
                message: Text(userVM.alertMessage),
                dismissButton: .default(Text("login_error_cta_dismiss", bundle: Bundle.module)))
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
