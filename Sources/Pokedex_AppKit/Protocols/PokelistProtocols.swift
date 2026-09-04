#if canImport(AppKit) && !canImport(UIKit)
import AppKit
import Pokedex_Shared_Backend

// MARK: - View

public protocol PokelistViewProtocol: AnyObject {
    var presenter: PokelistPresenterProtocol? { get set }
    func showPokemons()
    func showError(_ error: Error)
    func showLoading()
    func hideLoading()
}

// MARK: - Presenter

public protocol PokelistPresenterProtocol: AnyObject {
    var view: PokelistViewProtocol? { get set }
    var interactor: PokelistInteractorProtocol? { get set }
    var router: PokelistRouterProtocol? { get set }

    func viewDidLoad()
    func loadMorePokemons()
    func cancelLoading()
    func getPokemons() -> [PokemonEntity]
    func didSelectPokemon(at index: Int)
}

// MARK: - Interactor

public protocol PokelistInteractorProtocol: AnyObject {
    var presenter: PokelistInteractorOutputProtocol? { get set }
    func fetchPokemons(limit: Int, offset: Int)
    func cancelFetch()
}

// MARK: - Interactor Output

public protocol PokelistInteractorOutputProtocol: AnyObject {
    func didFetchPokemons(_ pokemons: [PokemonEntity])
    func didFailFetchingPokemons(with error: Error)
}

// MARK: - Router

/// The AppKit counterpart of `Pokedex_Pokelist.PokelistRouterProtocol`. The only shape change is
/// `NSViewController` in place of `UIViewController` — and presentation, since AppKit has no
/// navigation stack to push onto.
public protocol PokelistRouterProtocol: AnyObject {
    static func createModule(pokemonService: PokemonService) -> NSViewController
    func navigateToPokemonDetail(from view: NSViewController?, with id: Int)
}
#endif
