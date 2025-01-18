// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class PokemonListQuery: GraphQLQuery {
  public static let operationName: String = "PokemonList"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query PokemonList($limit: Int!, $offset: Int!, $spritePath: String!) { pokemon_v2_pokemon(limit: $limit, offset: $offset) { __typename id name pokemon_v2_pokemonsprites { __typename sprites(path: $spritePath) } } }"#
    ))

  public var limit: Int
  public var offset: Int
  public var spritePath: String

  public init(
    limit: Int,
    offset: Int,
    spritePath: String
  ) {
    self.limit = limit
    self.offset = offset
    self.spritePath = spritePath
  }

  public var __variables: Variables? { [
    "limit": limit,
    "offset": offset,
    "spritePath": spritePath
  ] }

  public struct Data: API.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { API.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("pokemon_v2_pokemon", [Pokemon_v2_pokemon].self, arguments: [
        "limit": .variable("limit"),
        "offset": .variable("offset")
      ]),
    ] }

    /// fetch data from the table: "pokemon_v2_pokemon"
    public var pokemon_v2_pokemon: [Pokemon_v2_pokemon] { __data["pokemon_v2_pokemon"] }

    /// Pokemon_v2_pokemon
    ///
    /// Parent Type: `Pokemon_v2_pokemon`
    public struct Pokemon_v2_pokemon: API.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { API.Objects.Pokemon_v2_pokemon }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("name", String.self),
        .field("pokemon_v2_pokemonsprites", [Pokemon_v2_pokemonsprite].self),
      ] }

      public var id: Int { __data["id"] }
      public var name: String { __data["name"] }
      /// An array relationship
      public var pokemon_v2_pokemonsprites: [Pokemon_v2_pokemonsprite] { __data["pokemon_v2_pokemonsprites"] }

      /// Pokemon_v2_pokemon.Pokemon_v2_pokemonsprite
      ///
      /// Parent Type: `Pokemon_v2_pokemonsprites`
      public struct Pokemon_v2_pokemonsprite: API.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { API.Objects.Pokemon_v2_pokemonsprites }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("sprites", API.Jsonb.self, arguments: ["path": .variable("spritePath")]),
        ] }

        public var sprites: API.Jsonb { __data["sprites"] }
      }
    }
  }
}
