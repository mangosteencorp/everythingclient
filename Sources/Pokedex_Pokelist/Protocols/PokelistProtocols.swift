// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import Pokedex_Shared_Backend
import UIKit

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

public protocol PokelistRouterProtocol: AnyObject {
    static func createModule(pokemonService: PokemonService) -> UIViewController
    func navigateToPokemonDetail(from view: UIViewController?, with id: Int)
}
#endif
