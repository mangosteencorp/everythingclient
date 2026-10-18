#if DEBUG
import Pokedex_Shared_Backend
import Shared_UI_Support
import SwiftUI
import UIKit

/// Every Pokémon detail preview as a view of its own, so Xcode's canvas, the integration launcher
/// and the screenshot run all render the same thing. `detail` loads Pikachu from the live
/// PokeAPI — `PokemonService` has no stand-in yet.
public enum PokedexDetailPreviewCatalog: String, CaseIterable {
    case demo
    case detail

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            PokedexDetailDemoView()
        case .detail:
            UIViewControllerPreview {
                let viewModel = PokemonDetailViewModel(pokemonService: .shared)
                viewModel.loadPokemon(id: 25)
                return Self.pushed(PokemonDetailViewController(viewModel: viewModel))
            }
        }
    }

    /// Shows `viewController` pushed onto a stack, back button and all.
    @MainActor
    static func pushed(_ viewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigationController.pushViewController(viewController, animated: false)
        }
        return navigationController
    }
}
#endif
