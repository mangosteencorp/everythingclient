import Foundation
public enum TabRoute: Hashable {
    case movieFeed
    case marketplace
    case profile

    public var title: String {
        switch self {
        case .movieFeed: return "Movies"
        case .marketplace: return "Discover"
        case .profile: return "Profile"
        }
    }

    public var iconName: String {
        switch self {
        case .movieFeed: return "play.circle"
        case .marketplace: return "cart"
        case .profile: return "person.crop.circle"
        }
    }
}
