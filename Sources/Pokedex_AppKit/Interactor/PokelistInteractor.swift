#if canImport(AppKit) && !canImport(UIKit)
import Foundation
import Pokedex_Shared_Backend

public final class PokelistInteractor: PokelistInteractorProtocol {
    public weak var presenter: PokelistInteractorOutputProtocol?
    private let pokemonService: PokemonService
    private var fetchTask: Task<Void, Never>?

    public init(pokemonService: PokemonService) {
        self.pokemonService = pokemonService
    }

    deinit {
        fetchTask?.cancel()
    }

    public func fetchPokemons(limit: Int, offset: Int) {
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let pokemons = try await pokemonService.fetchPokemons(limit: limit, offset: offset)
                let pokemonEntities = pokemons.map { PokemonEntity(from: $0) }
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.presenter?.didFetchPokemons(pokemonEntities)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.presenter?.didFailFetchingPokemons(with: error)
                }
            }
        }
    }

    /// Stops an in-flight page request; the presenter clears its loading flag separately.
    public func cancelFetch() {
        fetchTask?.cancel()
        fetchTask = nil
    }
}
#endif
