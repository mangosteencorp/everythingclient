import Foundation
import Pokedex_Shared_Backend

public final class PokelistInteractor: PokelistInteractorProtocol {
    public weak var presenter: PokelistInteractorOutputProtocol?
    private let pokemonService: PokemonService
    
    public init(pokemonService: PokemonService) {
        self.pokemonService = pokemonService
    }
    
    public func fetchPokemons(limit: Int, offset: Int) {
        Task {
            do {
                let pokemons = try await pokemonService.fetchPokemons(limit: limit, offset: offset)
                let pokemonEntities = pokemons.map { PokemonEntity(from: $0) }
                await MainActor.run {
                    self.presenter?.didFetchPokemons(pokemonEntities)
                }
            } catch {
                await MainActor.run {
                    self.presenter?.didFailFetchingPokemons(with: error)
                }
            }
        }
    }
} 
