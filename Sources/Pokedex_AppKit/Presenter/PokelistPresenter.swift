#if canImport(AppKit) && !canImport(UIKit)
import AppKit
import Foundation

public final class PokelistPresenter: PokelistPresenterProtocol {
    public init() {}

    public weak var view: PokelistViewProtocol?
    public var interactor: PokelistInteractorProtocol?
    public var router: PokelistRouterProtocol?

    private var pokemons: [PokemonEntity] = []
    private var isLoading = false

    public func viewDidLoad() {
        loadMorePokemons()
    }

    public func loadMorePokemons() {
        guard !isLoading else { return }
        isLoading = true
        view?.showLoading()
        interactor?.fetchPokemons(limit: 20, offset: pokemons.count)
    }

    /// Called when the list goes away: stops the request and clears the loading flag, which
    /// otherwise stays `true` forever and blocks any later page.
    public func cancelLoading() {
        guard isLoading else { return }
        interactor?.cancelFetch()
        isLoading = false
        view?.hideLoading()
    }

    public func getPokemons() -> [PokemonEntity] {
        return pokemons
    }

    public func didSelectPokemon(at index: Int) {
        guard pokemons.indices.contains(index) else { return }
        router?.navigateToPokemonDetail(from: view as? NSViewController, with: pokemons[index].id)
    }
}

// MARK: - PokelistInteractorOutputProtocol

extension PokelistPresenter: PokelistInteractorOutputProtocol {
    public func didFetchPokemons(_ newPokemons: [PokemonEntity]) {
        pokemons.append(contentsOf: newPokemons)
        isLoading = false
        view?.hideLoading()
        view?.showPokemons()
    }

    public func didFailFetchingPokemons(with error: Error) {
        isLoading = false
        view?.hideLoading()
        view?.showError(error)
    }
}
#endif
