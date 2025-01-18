import SwiftUI
import Pokedex_Pokelist
import Pokedex_Shared_Backend

public struct PokedexView: UIViewControllerRepresentable {
    public init() {}
    
    public func makeUIViewController(context: Context) -> PokelistViewController {
        return PokelistViewController(pokemonService: PokemonService.shared)
    }
    
    public func updateUIViewController(_ uiViewController: PokelistViewController, context: Context) {
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
    }
} 