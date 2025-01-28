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
    
    public init() {}
    
    public var body: some View {
        
        NavigationView {
            PokedexView()
                .navigationTitle("Pokédex")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
    }
}
#if DEBUG
@available(iOS 14.0, *)
#Preview {
    PokedexTabView()
}
#endif
