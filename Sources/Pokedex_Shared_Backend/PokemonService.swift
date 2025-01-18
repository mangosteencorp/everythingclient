import Foundation
import Apollo

public class PokemonService {
    // Singleton instance
    public static let shared = PokemonService()
    
    // Private Apollo client
    private let apollo: ApolloClient
    
    private init() {
        self.apollo = ApolloClient(url: URL(string: "https://beta.pokeapi.co/graphql/v1beta")!)
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
                case .success(let response):
                    let pokemons = response.data?.pokemon_v2_pokemon.compactMap { pokemon -> Pokemon? in
                        guard let spriteString = pokemon.pokemon_v2_pokemonsprites.first?.sprites,
                              let spriteData = spriteString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: spriteData) as? String
                        else {
                            return nil
                        }
                        
                        return Pokemon(
                            id: pokemon.id,
                            name: pokemon.name.capitalized,
                            imageURL: json
                        )
                    } ?? []
                    continuation.resume(returning: pokemons)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

