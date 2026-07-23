import Foundation
public enum TabRoute: Hashable {
    case movieFeed
    case marketplace
    case profile
    case settings

    public var title: String {
        switch self {
        case .movieFeed: return "Movies"
        case .marketplace: return "Discover"
        case .profile: return "Profile"
        case .settings: return "Settings"
        }
    }

    public var iconName: String {
        switch self {
        case .movieFeed: return "play.circle"
        case .marketplace: return "cart"
        case .profile: return "person.crop.circle"
        case .settings: return "gearshape"
        }
    }
}
