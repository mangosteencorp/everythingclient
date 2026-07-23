import Foundation

enum PokemonMovieMatcher {
    private static let keywordIds: Set<Int> = [
        11_551,  // pocket monsters
        222_288,
    ]

    private static let terms = [
        "pokemon",
        "pokémon",
        "pocket monsters",
        "pikachu",
        "ash ketchum",
        "pokédex",
        "pokedex",
    ]

    static func shouldShowPokedexButton(for movie: Movie) -> Bool {
        if let keywords = movie.keywords?.keywords, keywords.contains(where: matchesKeyword) {
            return true
        }

        return terms.contains { term in
            movie.title.localizedCaseInsensitiveContains(term)
                || movie.originalTitle.localizedCaseInsensitiveContains(term)
                || movie.overview.localizedCaseInsensitiveContains(term)
        }
    }

    private static func matchesKeyword(_ keyword: Keyword) -> Bool {
        keywordIds.contains(keyword.id) || terms.contains { term in
            keyword.name.localizedCaseInsensitiveContains(term)
        }
    }
}
