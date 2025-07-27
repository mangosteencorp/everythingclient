import Pokedex_Shared_Backend
import Shared_UI_Support
import SwiftUI

#if DEBUG
public struct PokedexListDemoView: View {
    public init() {}

    public var body: some View {
        UIViewControllerPreview {
            ExamplePokelistRouter.createModule(pokemonService: pokemonService)
        }
    }
}

#if DEBUG
#Preview {
    PokedexListDemoView()
}
#endif
#endif