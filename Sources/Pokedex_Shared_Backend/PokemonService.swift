import Apollo
import Foundation

public class PokemonService {
    // Singleton instance
    public static let shared = PokemonService()

    // Private Apollo client
    private let apollo: ApolloClient

    private init() {
        apollo = ApolloClient(url: URL(string: "https://beta.pokeapi.co/graphql/v1beta")!)
    }

    public func fetchPokemons(limit: Int = 50, offset: Int = 0) async throws -> [Pokemon] {
        return try await withCheckedThrowingContinuation { continuation in
            let query = PokemonListQuery(
                limit: limit,
                offset: offset,
                spritePath: "front_shiny"
            )
            apollo.fetch(query: query) { result in
                switch result {
                case let .success(response):
                    let pokemons = response.data?.pokemon_v2_pokemon.compactMap { pokemon -> Pokemon? in
                        guard let spriteString = pokemon.pokemon_v2_pokemonsprites.first?.sprites as? String
                        else { return nil }

                        return Pokemon(
                            id: pokemon.id,
                            name: pokemon.name.capitalized,
                            imageURL: spriteString
                        )
                    } ?? []
                    continuation.resume(returning: pokemons)

                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func fetchPokemonDetail(id: Int) async throws -> PokemonDetail? {
        return try await withCheckedThrowingContinuation { continuation in
            let query = PokemonDetailQuery(id: id, spritePath: "other.showdown.front_shiny")

            apollo.fetch(query: query) { result in
                switch result {
                case let .success(response):
                    guard let pokemonData = response.data?.pokemon_v2_pokemon.first else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let moves = pokemonData.pokemon_v2_pokemonmoves.map { move in
                        PokemonDetail.Move(
                            id: move.id,
                            moveId: move.move_id ?? 0,
                            name: move.pokemon_v2_move?.name ?? ""
                        )
                    }

                    let abilities = pokemonData.pokemon_v2_pokemonabilities.map { ability in
                        PokemonDetail.Ability(
                            abilityId: ability.ability_id ?? 0,
                            name: ability.pokemon_v2_ability?.name ?? ""
                        )
                    }

                    let stats = pokemonData.pokemon_v2_pokemonstats.map { stat in
                        PokemonDetail.Stat(
                            statId: stat.stat_id ?? 0,
                            baseStat: stat.base_stat,
                            effort: stat.effort,
                            name: stat.pokemon_v2_stat?.name ?? ""
                        )
                    }

                    let pokemon = PokemonDetail(
                        id: pokemonData.id,
                        name: pokemonData.name.capitalized,
                        imageURL: pokemonData.pokemon_v2_pokemonsprites.first?.sprites ?? "",
                        weight: pokemonData.weight ?? 0,
                        speciesId: pokemonData.pokemon_species_id ?? 0,
                        moves: moves,
                        abilities: abilities,
                        stats: stats
                    )

                    continuation.resume(returning: pokemon)

                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
