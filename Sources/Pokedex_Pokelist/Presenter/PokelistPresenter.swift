import Foundation

final class PokelistPresenter: PokelistPresenterProtocol {
    weak var view: PokelistViewProtocol?
    var interactor: PokelistInteractorProtocol?
    var router: PokelistRouterProtocol?
    
    private var pokemons: [PokemonEntity] = []
    private var isLoading = false
    
    func viewDidLoad() {
        loadMorePokemons()
    }
    
    func loadMorePokemons() {
        guard !isLoading else { return }
        isLoading = true
        view?.showLoading()
        interactor?.fetchPokemons(limit: 20, offset: pokemons.count)
    }
    
    func getPokemons() -> [PokemonEntity] {
        return pokemons
    }
}

// MARK: - PokelistInteractorOutputProtocol
extension PokelistPresenter: PokelistInteractorOutputProtocol {
    func didFetchPokemons(_ newPokemons: [PokemonEntity]) {
        pokemons.append(contentsOf: newPokemons)
        isLoading = false
        view?.hideLoading()
        view?.showPokemons()
    }
    
    func didFailFetchingPokemons(with error: Error) {
        isLoading = false
        view?.hideLoading()
        view?.showError(error)
    }
} 