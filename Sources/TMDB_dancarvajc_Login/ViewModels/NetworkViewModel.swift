import Combine
final class NetworkViewModel: ObservableObject{
    @Published var noInternet: Bool = false
    @Published var noWifinoCelularData: Bool = false

    // Subscribes to and publishes the states of NetworkManager
    init(networkMg: NetworkManager) {
        
        networkMg.$noInternet
            .assign(to: &$noInternet)
        
        networkMg.$noWifiNoCellularData
            .assign(to: &$noWifinoCelularData)

    }
    
}
