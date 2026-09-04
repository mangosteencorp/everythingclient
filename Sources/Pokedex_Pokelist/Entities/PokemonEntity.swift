// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
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
        id = pokemon.id
        name = pokemon.name
        imageURL = pokemon.imageURL
    }
}
#endif
