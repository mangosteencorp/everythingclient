import CoreFeatures
import SwiftUI

/// How the *inner* feed tab level is presented.
///
/// Adding a look (Mail chips, Podcast rows, `UIPageViewController` pages, …) is one case here,
/// one file in `Design/TabLayouts/`, and one arm in `FeedTabContainer`.
public enum FeedTabDesign: String, DesignVariant {
    /// System `TabView`, complete with its "More" overflow list.
    case systemTabs
    /// Scrollable segment header pinned above the content.
    case topSegments

    public static var slotTitle: String { "Feed Tabs" }

    public static var fallback: FeedTabDesign { .topSegments }

    public var displayName: String {
        switch self {
        case .systemTabs: return "System Tabs"
        case .topSegments: return "Top Segments"
        }
    }

    public var isAvailableOnThisDevice: Bool {
        switch self {
        case .systemTabs:
            #if targetEnvironment(macCatalyst)
            // Catalyst promotes system tabs to the window toolbar, which the app shell
            // already owns. Keep feed categories inside the content with Top Segments.
            return false
            #else
            // On iPhone the app shell already owns the bottom edge; a second bottom bar inside
            // it is unusable. iPad puts both levels at the top, so it stays available there.
            return UIDevice.current.userInterfaceIdiom == .pad
            #endif
        case .topSegments:
            return true
        }
    }
}
