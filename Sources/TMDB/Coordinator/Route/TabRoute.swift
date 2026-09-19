import CoreFeatures
import Foundation
import TMDB_Feed

public enum TabRoute: Hashable {
    case movieFeed
    case marketplace
    case profile
    case settings
    /// One feed category standing on its own — a sidebar row in `SectionedSidebarShell`, or
    /// the search tab. Never part of `Coordinator.tabList`; shells add it on demand.
    case feedRow(FeedTab)

    public var title: String {
        switch self {
        case .movieFeed: return "Movies"
        case .marketplace: return "Discover"
        case .profile: return "Profile"
        case .settings: return "Settings"
        case let .feedRow(tab): return tab.title
        }
    }

    public var iconName: String {
        switch self {
        case .movieFeed: return "play.circle"
        case .marketplace: return "cart"
        case .profile: return "person.crop.circle"
        case .settings: return "gearshape"
        case let .feedRow(tab): return tab.systemImage
        }
    }
}

extension TabRoute: ShellTabItem {
    public var systemImage: String { iconName }

    public var customizationID: String {
        switch self {
        case .movieFeed: return "tab.movieFeed"
        case .marketplace: return "tab.marketplace"
        case .profile: return "tab.profile"
        case .settings: return "tab.settings"
        case let .feedRow(tab): return tab.customizationID
        }
    }
}
