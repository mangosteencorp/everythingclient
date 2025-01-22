import SwiftUI
import Combine
import Pokedex_Pokelist
import Pokedex_Shared_Backend

public struct PokedexView: UIViewControllerRepresentable {
    public init() {}
    
    public func makeUIViewController(context: Context) -> UIViewController {
        return PokelistRouter.createModule(pokemonService: PokemonService.shared)
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Updates can be handled here if needed
    }
}

@available(iOS 14.0, *)
public struct PokedexTabView: View {
    @StateObject private var orientationMonitor = OrientationMonitor()
    public init() {}
    
    public var body: some View {
        
        NavigationView {
            PokedexView()
                .navigationTitle("Pokédex")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
    }
}
class OrientationMonitor: ObservableObject {
    @Published var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    
    private var cancellable: AnyCancellable?
    
    init() {
        // Create a publisher for orientation changes
        cancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .map { _ in UIDevice.current.orientation.isLandscape }
            .removeDuplicates()
            .assign(to: \.isLandscape, on: self)
    }
}
#if DEBUG
@available(iOS 14.0, *)
#Preview {
    PokedexTabView()
}
#endif
