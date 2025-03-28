// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == Pokedex_Shared_Backend.SchemaMetadata {}

public protocol InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == Pokedex_Shared_Backend.SchemaMetadata {}

public protocol MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == Pokedex_Shared_Backend.SchemaMetadata {}

public protocol MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == Pokedex_Shared_Backend.SchemaMetadata {}

public enum SchemaMetadata: ApolloAPI.SchemaMetadata {
  public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

  public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
    switch typename {
    case "pokemon_v2_ability": return Pokedex_Shared_Backend.Objects.Pokemon_v2_ability
    case "pokemon_v2_move": return Pokedex_Shared_Backend.Objects.Pokemon_v2_move
    case "pokemon_v2_pokemon": return Pokedex_Shared_Backend.Objects.Pokemon_v2_pokemon
    case "pokemon_v2_pokemonability": return Pokedex_Shared_Backend.Objects.Pokemon_v2_pokemonability
    case "pokemon_v2_pokemonmove": return Pokedex_Shared_Backend.Objects.Pokemon_v2_pokemonmove
    case "pokemon_v2_pokemonsprites": return Pokedex_Shared_Backend.Objects.Pokemon_v2_pokemonsprites
    case "pokemon_v2_pokemonstat": return Pokedex_Shared_Backend.Objects.Pokemon_v2_pokemonstat
    case "pokemon_v2_stat": return Pokedex_Shared_Backend.Objects.Pokemon_v2_stat
    case "query_root": return Pokedex_Shared_Backend.Objects.Query_root
    default: return nil
    }
  }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
