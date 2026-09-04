#if canImport(AppKit) && !canImport(UIKit)
import AppKit
import Pokedex_Shared_Backend

/// Wires the AppKit VIPER module together.
///
/// Structurally identical to `Pokedex.PokelistRouter`, except that navigation is a sheet:
/// AppKit has no `UINavigationController` to push onto.
public final class PokelistRouter: PokelistRouterProtocol {
    private let pokemonService: PokemonService

    private init(pokemonService: PokemonService) {
        self.pokemonService = pokemonService
    }

    public static func createModule(pokemonService: PokemonService) -> NSViewController {
        let view = PokelistViewController()
        let presenter = PokelistPresenter()
        let interactor = PokelistInteractor(pokemonService: pokemonService)
        let router = PokelistRouter(pokemonService: pokemonService)

        view.presenter = presenter
        presenter.view = view
        presenter.router = router
        presenter.interactor = interactor
        interactor.presenter = presenter

        return view
    }

    public func navigateToPokemonDetail(from view: NSViewController?, with id: Int) {
        let detail = PokemonDetailViewController(pokemonID: id, pokemonService: pokemonService)
        view?.presentAsSheet(detail)
    }
}
#endif
