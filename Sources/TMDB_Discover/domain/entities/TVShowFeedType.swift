import Foundation
public enum TVShowFeedType: Hashable, Codable {
    case airingToday
    case onTheAir
    case discover

    var title: String {
        switch self {
        case .airingToday:
            return "Airing Today"
        case .onTheAir:
            return "On the air"
        case .discover:
            return "Discover Movies"
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
        }
    }
}
