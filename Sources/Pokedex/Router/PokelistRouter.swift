import Pokedex_Detail
import Pokedex_Pokelist
import Pokedex_Shared_Backend
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public final class PokelistRouter: PokelistRouterProtocol {
    public static func createModule(pokemonService: PokemonService) -> PlatformViewController {
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

    public func navigateToPokemonDetail(from view: PlatformViewController?, with id: Int) {
        let viewModel = PokemonDetailViewModel(pokemonService: .shared)
        let detailVC = PokemonDetailViewController(viewModel: viewModel)
        viewModel.loadPokemon(id: id)

        #if canImport(UIKit)
        view?.navigationController?.pushViewController(detailVC, animated: true)
        #elseif canImport(AppKit)
        guard let presentingView = view else { return }
        presentingView.presentAsModalWindow(detailVC)
        #endif
    }
}
