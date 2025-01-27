import SwiftUI
import Pokedex_Shared_Backend
import Shared_UI_Support

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
