import Combine
import SwiftUI
#if canImport(UIKit)
import Pokedex_Pokelist
import Pokedex_Shared_Backend
import UIKit
#elseif canImport(AppKit)
import AppKit
import Pokedex_AppKit
import Pokedex_Shared_Backend
#endif

/// The Pokédex list, bridged into SwiftUI.
///
/// Both platforms mount a VIPER module built on the *same* `Pokedex_Shared_Backend`; only the UI
/// framework differs — UIKit (`Pokedex_Pokelist`) on iOS, AppKit (`Pokedex_AppKit`) on macOS.
#if canImport(UIKit)
public struct PokedexView: UIViewControllerRepresentable {
    public init() {}

    public func makeUIViewController(context: Context) -> UIViewController {
        return PokelistRouter.createModule(pokemonService: PokemonService.shared)
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Updates can be handled here if needed
    }
}

#elseif canImport(AppKit)
public struct PokedexView: NSViewControllerRepresentable {
    public init() {}

    public func makeNSViewController(context: Context) -> NSViewController {
        return Pokedex_AppKit.PokelistRouter.createModule(pokemonService: PokemonService.shared)
    }

    public func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        // Updates can be handled here if needed
    }
}
#endif

@available(iOS 14.0, *)
public struct PokedexTabView: View {
    public init() {}

    public var body: some View {
        NavigationView {
            PokedexView()
                .navigationTitle("Pokédex")
        }
        // `StackNavigationViewStyle` is iOS/tvOS only; macOS keeps the default split style.
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
    }
}

#if DEBUG
@available(iOS 14.0, *)
#Preview {
    PokedexTabView()
}
#endif
