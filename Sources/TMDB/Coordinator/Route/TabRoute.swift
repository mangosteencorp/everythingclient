import Foundation
public enum TabRoute: Hashable {
    case nowPlaying
    case upcoming
    case profile

    public var title: String {
        switch self {
        case .nowPlaying: return "Now Playing"
        case .upcoming: return "Upcoming"
        case .profile: return "Profile"
        }
    }

    public var iconName: String {
        switch self {
        case .nowPlaying: return "play.circle"
        case .upcoming: return "magnifyingglass"
        case .profile: return "list.bullet"
        }
    }
}
