import SwiftUI
import TMDB_Shared_Backend
public struct ProfileTabView: View {
    let networkManager = NetworkManager()
    let keychainManager = KeychainManager()
    
    public init(_ apiKey: String = ""){
        EndPoint.apiKey = apiKey
    }
    public var body: some View {
        ProfileView()
            .environmentObject(UserViewModel(service: networkManager, keychainM: keychainManager))
            .environmentObject(MoviesViewModel(service: networkManager, keychainM: keychainManager))
            .environmentObject(NetworkViewModel(networkMg: networkManager))
    }
}
