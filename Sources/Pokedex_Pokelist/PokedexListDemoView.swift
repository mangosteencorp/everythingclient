// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import Pokedex_Shared_Backend
import Shared_UI_Support
import Shared_UI_Support_UIKit
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
#endif
