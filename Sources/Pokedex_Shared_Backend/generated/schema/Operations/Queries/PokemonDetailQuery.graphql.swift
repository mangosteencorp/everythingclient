// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class PokemonDetailQuery: GraphQLQuery {
  public static let operationName: String = "PokemonDetail"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query PokemonDetail($id: Int!, $spritePath: String!) { pokemon_v2_pokemon(where: { id: { _eq: $id } }) { __typename id name weight pokemon_species_id pokemon_v2_pokemonmoves(distinct_on: move_id) { __typename move_id id pokemon_v2_move { __typename name } } pokemon_v2_pokemonsprites { __typename sprites(path: $spritePath) } pokemon_v2_pokemonabilities { __typename ability_id pokemon_v2_ability { __typename name } } pokemon_v2_pokemonstats { __typename stat_id base_stat effort pokemon_v2_stat { __typename name } } } }"#
    ))

  public var id: Int
  public var spritePath: String

  public init(
    id: Int,
    spritePath: String
  ) {
    self.id = id
    self.spritePath = spritePath
  }

  public var __variables: Variables? { [
    "id": id,
    "spritePath": spritePath
  ] }

  public struct Data: Pokedex_Shared_Backend.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { Pokedex_Shared_Backend.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("pokemon_v2_pokemon", [Pokemon_v2_pokemon].self, arguments: ["where": ["id": ["_eq": .variable("id")]]]),
    ] }

    /// fetch data from the table: "pokemon_v2_pokemon"
    public var pokemon_v2_pokemon: [Pokemon_v2_pokemon] { __data["pokemon_v2_pokemon"] }

    /// Pokemon_v2_pokemon
    ///
    /// Parent Type: `Pokemon_v2_pokemon`
    public struct Pokemon_v2_pokemon: Pokedex_Shared_Backend.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { Pokedex_Shared_Backend.Objects.Pokemon_v2_pokemon }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("name", String.self),
        .field("weight", Int?.self),
        .field("pokemon_species_id", Int?.self),
        .field("pokemon_v2_pokemonmoves", [Pokemon_v2_pokemonmofe].self, arguments: ["distinct_on": "move_id"]),
        .field("pokemon_v2_pokemonsprites", [Pokemon_v2_pokemonsprite].self),
        .field("pokemon_v2_pokemonabilities", [Pokemon_v2_pokemonability].self),
        .field("pokemon_v2_pokemonstats", [Pokemon_v2_pokemonstat].self),
      ] }

      public var id: Int { __data["id"] }
      public var name: String { __data["name"] }
      public var weight: Int? { __data["weight"] }
      public var pokemon_species_id: Int? { __data["pokemon_species_id"] }
      /// An array relationship
      public var pokemon_v2_pokemonmoves: [Pokemon_v2_pokemonmofe] { __data["pokemon_v2_pokemonmoves"] }
      /// An array relationship
      public var pokemon_v2_pokemonsprites: [Pokemon_v2_pokemonsprite] { __data["pokemon_v2_pokemonsprites"] }
      /// An array relationship
      public var pokemon_v2_pokemonabilities: [Pokemon_v2_pokemonability] { __data["pokemon_v2_pokemonabilities"] }
      /// An array relationship
      public var pokemon_v2_pokemonstats: [Pokemon_v2_pokemonstat] { __data["pokemon_v2_pokemonstats"] }

      /// Pokemon_v2_pokemon.Pokemon_v2_pokemonmofe
      ///
      /// Parent Type: `Pokemon_v2_pokemonmove`
      public struct Pokemon_v2_pokemonmofe: Pokedex_Shared_Backend.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { Pokedex_Shared_Backend.Objects.Pokemon_v2_pokemonmove }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("move_id", Int?.self),
          .field("id", Int.self),
          .field("pokemon_v2_move", Pokemon_v2_move?.self),
        ] }

        public var move_id: Int? { __data["move_id"] }
        public var id: Int { __data["id"] }
        /// An object relationship
        public var pokemon_v2_move: Pokemon_v2_move? { __data["pokemon_v2_move"] }

        /// Pokemon_v2_pokemon.Pokemon_v2_pokemonmofe.Pokemon_v2_move
        ///
        /// Parent Type: `Pokemon_v2_move`
        public struct Pokemon_v2_move: Pokedex_Shared_Backend.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { Pokedex_Shared_Backend.Objects.Pokemon_v2_move }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("name", String.self),
          ] }

          public var name: String { __data["name"] }
        }
      }

      /// Pokemon_v2_pokemon.Pokemon_v2_pokemonsprite
      ///
      /// Parent Type: `Pokemon_v2_pokemonsprites`
      public struct Pokemon_v2_pokemonsprite: Pokedex_Shared_Backend.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { Pokedex_Shared_Backend.Objects.Pokemon_v2_pokemonsprites }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("sprites", Pokedex_Shared_Backend.Jsonb.self, arguments: ["path": .variable("spritePath")]),
        ] }

        public var sprites: Pokedex_Shared_Backend.Jsonb { __data["sprites"] }
      }

      /// Pokemon_v2_pokemon.Pokemon_v2_pokemonability
      ///
      /// Parent Type: `Pokemon_v2_pokemonability`
      public struct Pokemon_v2_pokemonability: Pokedex_Shared_Backend.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { Pokedex_Shared_Backend.Objects.Pokemon_v2_pokemonability }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("ability_id", Int?.self),
          .field("pokemon_v2_ability", Pokemon_v2_ability?.self),
        ] }

        public var ability_id: Int? { __data["ability_id"] }
        /// An object relationship
        public var pokemon_v2_ability: Pokemon_v2_ability? { __data["pokemon_v2_ability"] }

        /// Pokemon_v2_pokemon.Pokemon_v2_pokemonability.Pokemon_v2_ability
        ///
        /// Parent Type: `Pokemon_v2_ability`
        public struct Pokemon_v2_ability: Pokedex_Shared_Backend.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { Pokedex_Shared_Backend.Objects.Pokemon_v2_ability }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("name", String.self),
          ] }

          public var name: String { __data["name"] }
        }
      }

      /// Pokemon_v2_pokemon.Pokemon_v2_pokemonstat
      ///
      /// Parent Type: `Pokemon_v2_pokemonstat`
      public struct Pokemon_v2_pokemonstat: Pokedex_Shared_Backend.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { Pokedex_Shared_Backend.Objects.Pokemon_v2_pokemonstat }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("stat_id", Int?.self),
          .field("base_stat", Int.self),
          .field("effort", Int.self),
          .field("pokemon_v2_stat", Pokemon_v2_stat?.self),
        ] }

        public var stat_id: Int? { __data["stat_id"] }
        public var base_stat: Int { __data["base_stat"] }
        public var effort: Int { __data["effort"] }
        /// An object relationship
        public var pokemon_v2_stat: Pokemon_v2_stat? { __data["pokemon_v2_stat"] }

        /// Pokemon_v2_pokemon.Pokemon_v2_pokemonstat.Pokemon_v2_stat
        ///
        /// Parent Type: `Pokemon_v2_stat`
        public struct Pokemon_v2_stat: Pokedex_Shared_Backend.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { Pokedex_Shared_Backend.Objects.Pokemon_v2_stat }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("name", String.self),
          ] }

          public var name: String { __data["name"] }
        }
      }
    }
  }
}
