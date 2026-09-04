// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import Pokedex_Detail
import Pokedex_Pokelist
import Pokedex_Shared_Backend
import UIKit

public final class PokelistRouter: PokelistRouterProtocol {
    public static func createModule(pokemonService: PokemonService) -> UIViewController {
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

    public func navigateToPokemonDetail(from view: UIViewController?, with id: Int) {
        let viewModel = PokemonDetailViewModel(pokemonService: .shared)
        let detailVC = PokemonDetailViewController(viewModel: viewModel)
        viewModel.loadPokemon(id: id)

        view?.navigationController?.pushViewController(detailVC, animated: true)
    }
}
#endif
