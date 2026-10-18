#if DEBUG
import Pokedex_Shared_Backend
import Shared_UI_Support
import SwiftUI

/// Every Pokémon list preview as a view of its own, so Xcode's canvas, the integration launcher
/// and the screenshot run all render the same thing. Both load from the live PokeAPI —
/// `PokemonService` has no stand-in yet.
public enum PokedexPokelistPreviewCatalog: String, CaseIterable {
    case demo
    case list

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            PokedexListDemoView()
        case .list:
            UIViewControllerPreview { ExamplePokelistRouter.createModule(pokemonService: pokemonService) }
        }
    }
}
#endif
