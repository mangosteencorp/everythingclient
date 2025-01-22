import Foundation
import Pokedex_Shared_Backend
public struct PokemonEntity {
    public let id: Int
    public let name: String
    public let imageURL: String
    
    init(id: Int, name: String, imageURL: String) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
    }
    
    init(from pokemon: Pokemon) {
        self.id = pokemon.id
        self.name = pokemon.name
        self.imageURL = pokemon.imageURL
    }
} 
