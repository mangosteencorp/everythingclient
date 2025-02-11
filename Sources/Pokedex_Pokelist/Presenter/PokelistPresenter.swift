import Foundation
import UIKit
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
    
    public func getPokemons() -> [PokemonEntity] {
        return pokemons
    }
    
    public func didSelectPokemon(at index: Int) {
        router?.navigateToPokemonDetail(from: view as? UIViewController, with: getPokemons()[index].id)
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
