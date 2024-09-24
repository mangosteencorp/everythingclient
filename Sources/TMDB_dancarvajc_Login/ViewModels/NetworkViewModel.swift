import Combine
final class NetworkViewModel: ObservableObject{
    @Published var noInternet: Bool = false
    @Published var noWifinoCelularData: Bool = false

    //Se suscribe y publican los estados de NetworkManager
    init(networkMg: NetworkManager) {
        
        networkMg.$noInternet
            .assign(to: &$noInternet)
        
        networkMg.$noWifinoCelularData
            .assign(to: &$noWifinoCelularData)

    }
    
}
