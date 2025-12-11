import Pokedex_Shared_Backend
import Shared_UI_Support
import SwiftUI

#if DEBUG && canImport(UIKit)
public struct PokedexListDemoView: View {
    public init() {}

    public var body: some View {

        UIViewControllerPreview {
            ExamplePokelistRouter.createModule(pokemonService: pokemonService)
        }

    }
}


#Preview {
    PokedexListDemoView()
}

#endif
