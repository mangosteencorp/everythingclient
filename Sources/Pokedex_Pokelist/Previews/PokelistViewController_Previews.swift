import SwiftUI
import Pokedex_Shared_Backend
import Shared_UI_Support

#if DEBUG
let pokemonService = PokemonService.shared
//let previewViewController = PokelistRouter.createModule(pokemonService: pokemonService)
#Preview {
    UIViewControllerPreview {
        UIViewController()
    }
}
#endif
