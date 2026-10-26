import Foundation

public enum TVShowFeedType: Hashable, Codable {
    case discoverWithGenre(Genre) // For movie genres
    case discoverWithTVGenre(Genre) // For TV genres

    var title: String {
        switch self {
        case let .discoverWithGenre(genre):
            return "\(genre.name) Movies"
        case let .discoverWithTVGenre(genre):
            return "\(genre.name) TV Shows"
        }
    }
}
