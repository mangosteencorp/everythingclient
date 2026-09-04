import CoreFeatures
import SwiftUI

/// How the *upper* tab level is presented.
///
/// Adding a shell is: one case here, one `isAvailableOnThisDevice` rule, one file in
/// `Design/Shells/`, one arm in `TMDBAPITabView.body`. Nothing else moves.
@available(iOS 16, *)
public enum AppShellDesign: String, DesignVariant {
    /// System `TabView` — bar at the bottom on iPhone, top on iPad.
    case bottomTabBar
    /// System `TabView` rendered as a leading sidebar (iOS 27+, iPad).
    case sidebarTabBar
    /// Custom glass/pill bar floating above the content.
    case floatingTabBar
    /// Full-bleed swipeable pages with a dot indicator, no bar.
    case pagedTabs

    public static var slotTitle: String { "App Shell" }

    public static var fallback: AppShellDesign { deviceDefault }

    /// Mirrors what `TMDBAPITabView` used to compute inline: iPhone gets the floating bar,
    /// iPad prefers the sidebar when the OS can render one.
    static var deviceDefault: AppShellDesign {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return .floatingTabBar
        }

        if #available(iOS 27, *) {
            return .sidebarTabBar
        }

        return .bottomTabBar
    }

    public var displayName: String {
        switch self {
        case .bottomTabBar: return "Bottom Tab Bar"
        case .sidebarTabBar: return "Sidebar Tab Bar"
        case .floatingTabBar: return "Floating Tab Bar"
        case .pagedTabs: return "Paged Tabs"
        }
    }

    public var isAvailableOnThisDevice: Bool {
        switch self {
        case .sidebarTabBar:
            // `defaultTabBarPlacement(.sidebar)` only exists on iOS 27, and a sidebar on a
            // phone-width window collapses back to a bottom bar anyway.
            guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
            if #available(iOS 27, *) { return true }
            return false
        case .bottomTabBar, .floatingTabBar, .pagedTabs:
            return true
        }
    }
}
