import Foundation
public enum TabRoute: Hashable {
    case movieFeed
    case tvShowFeed
    case marketplace
    case profile

    public var title: String {
        switch self {
        case .movieFeed: return "Movies"
        case .tvShowFeed: return "TV Shows"
        case .marketplace: return "Marketplace"
        case .profile: return "Profile"
        }
    }

    public var iconName: String {
        switch self {
        case .movieFeed: return "play.circle"
        case .tvShowFeed: return "tv.and.mediabox"
        case .marketplace: return "cart"
        case .profile: return "person.crop.circle"
        }
    }
}
