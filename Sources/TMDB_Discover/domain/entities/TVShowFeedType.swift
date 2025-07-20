import Foundation
public enum TVShowFeedType {
    case airingToday
    case onTheAir

    var title: String {
        switch self {
        case .airingToday:
            return "Airing Today"
        case .onTheAir:
            return "On the air"
        }
    }

    var iconName: String {
        switch self {
        case .airingToday:
            return "play.circle"
        case .onTheAir:
            return "calendar"
        }
    }
}
