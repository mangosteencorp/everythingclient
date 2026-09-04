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
let pokemonService = PokemonService.shared
class ExamplePokelistRouter: PokelistRouterProtocol {
    static func createModule(pokemonService: Pokedex_Shared_Backend.PokemonService) -> UIViewController {
        let presenter = PokelistPresenter()
        let interactor = PokelistInteractor(pokemonService: pokemonService)
        let router = ExamplePokelistRouter()
        let view = PokelistViewController()
        view.presenter = presenter
        presenter.view = view
        presenter.router = router
        presenter.interactor = interactor
        interactor.presenter = presenter
        return view
    }

    func navigateToPokemonDetail(from view: UIViewController?, with id: Int) {}
}

#Preview {
    UIViewControllerPreview {
        ExamplePokelistRouter.createModule(pokemonService: pokemonService)
    }
}
#endif
#endif
