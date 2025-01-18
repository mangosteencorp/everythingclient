import Foundation
import Pokedex_Shared_Backend
struct PokemonEntity {
    let id: Int
    let name: String
    let imageURL: String
    
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
