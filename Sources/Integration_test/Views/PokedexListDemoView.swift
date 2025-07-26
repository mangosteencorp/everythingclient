import Pokedex_Pokelist
import Pokedex_Shared_Backend
import Shared_UI_Support
import SwiftUI

struct PokedexListDemoView: View {
    var body: some View {
        UIViewControllerPreview {
            ExamplePokelistRouter.createModule(pokemonService: pokemonService)
        }
    }
}

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
    PokedexListDemoView()
}
#endif