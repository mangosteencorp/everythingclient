import CoreFeatures
import Foundation
import TMDB_Feed

public enum TabRoute: Hashable {
    case movieFeed
    case marketplace
    case profile
    case settings
    /// The scoped search page, rendered with `role: .search` by the sectioned shell.
    case search
    /// One feed category standing on its own — a sidebar row in `SectionedSidebarShell`.
    /// Never part of `Coordinator.tabList`; shells add it on demand.
    case feedRow(FeedTab)

    /// Tabs only the sectioned shell offers. Leaving one selected while switching to another
    /// shell would point at a tab that is not in `Coordinator.tabList`, and so a blank screen.
    var isSectionedShellOnly: Bool {
        switch self {
        case .search, .feedRow: return true
        case .movieFeed, .marketplace, .profile, .settings: return false
        }
    }

    public var title: String {
        switch self {
        case .movieFeed: return "Movies"
        case .marketplace: return "Discover"
        case .profile: return "Profile"
        case .settings: return "Settings"
        case .search: return "Search"
        case let .feedRow(tab): return tab.title
        }
    }

    public var iconName: String {
        switch self {
        case .movieFeed: return "play.circle"
        case .marketplace: return "cart"
        case .profile: return "person.crop.circle"
        case .settings: return "gearshape"
        case .search: return "magnifyingglass"
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
        case .search: return "tab.search"
        case let .feedRow(tab): return tab.customizationID
        }
    }
}
