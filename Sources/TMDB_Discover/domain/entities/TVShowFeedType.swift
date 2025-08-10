import Foundation
public enum TVShowFeedType: Hashable, Codable {
    case airingToday
    case onTheAir
    case discover
    case discoverWithGenre(Genre)

    var title: String {
        switch self {
        case .airingToday:
            return "Airing Today"
        case .onTheAir:
            return "On the air"
        case .discover:
            return "Discover Movies"
        case .discoverWithGenre(let genre):
            return "\(genre.name) Movies"
        }
    }

    var iconName: String {
        switch self {
        case .airingToday:
            return "play.circle"
        case .onTheAir:
            return "calendar"
        case .discover:
            return "magnifyingglass"
        case .discoverWithGenre(let genre):
            return "tag"
        }
    }
}
