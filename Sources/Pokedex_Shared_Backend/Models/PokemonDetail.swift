import Foundation

public struct PokemonDetail {
    public let id: Int
    public let name: String
    public let imageURL: String
    public let weight: Int
    public let speciesId: Int
    public let moves: [Move]
    public let abilities: [Ability]
    public let stats: [Stat]

    public struct Move {
        public let id: Int
        public let moveId: Int
        public let name: String

        public init(id: Int, moveId: Int, name: String) {
            self.id = id
            self.moveId = moveId
            self.name = name
        }
    }

    public struct Ability {
        public let abilityId: Int
        public let name: String

        public init(abilityId: Int, name: String) {
            self.abilityId = abilityId
            self.name = name
        }
    }

    public struct Stat {
        public let statId: Int
        public let baseStat: Int
        public let effort: Int
        public let name: String

        public init(statId: Int, baseStat: Int, effort: Int, name: String) {
            self.statId = statId
            self.baseStat = baseStat
            self.effort = effort
            self.name = name
        }
    }

    public init(
        id: Int,
        name: String,
        imageURL: String,
        weight: Int,
        speciesId: Int,
        moves: [Move],
        abilities: [Ability],
        stats: [Stat]
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.weight = weight
        self.speciesId = speciesId
        self.moves = moves
        self.abilities = abilities
        self.stats = stats
    }
}
