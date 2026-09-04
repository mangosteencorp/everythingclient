#if canImport(AppKit) && !canImport(UIKit)
import Foundation
import Pokedex_Shared_Backend

/// The list module's own view-facing model, mapped from the shared backend's `Pokemon`.
///
/// Deliberately a copy of `Pokedex_Pokelist.PokemonEntity` rather than a shared type: the point of
/// this module is that two front ends built on different UI frameworks sit on the *same* backend
/// (`Pokedex_Shared_Backend`) while owning their own presentation layer end to end.
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
        id = pokemon.id
        name = pokemon.name
        imageURL = pokemon.imageURL
    }
}
#endif
