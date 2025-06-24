import Foundation
public enum TabRoute: Hashable {
    case movieFeed
    case tvShowFeed
    case profile

    public var title: String {
        switch self {
        case .movieFeed: return "Movies"
        case .tvShowFeed: return "TV Shows"
        case .profile: return "Profile"
        }
    }

    public var iconName: String {
        switch self {
        case .movieFeed: return "play.circle"
        case .tvShowFeed: return "tv.and.mediabox"
        case .profile: return "person.crop.circle"
        }
    }
}
