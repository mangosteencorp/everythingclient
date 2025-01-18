import UIKit
import Pokedex_Shared_Backend

final class PokelistRouter: PokelistRouterProtocol {
    static func createModule(pokemonService: PokemonService) -> UIViewController {
        let view = PokelistViewController()
        let presenter = PokelistPresenter()
        let interactor = PokelistInteractor(pokemonService: pokemonService)
        let router = PokelistRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.router = router
        presenter.interactor = interactor
        interactor.presenter = presenter
        
        return view
    }
} 