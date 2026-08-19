import CoreFeatures
import SwiftUI

/// How the feed tab wraps its content for navigation.
@available(iOS 16, *)
public enum AppNavigationDesign: String, DesignVariant {
    /// Single column: rows push onto a `NavigationStack`.
    case plain
    /// Two columns: the feed stays on the left, the tapped title fills the right.
    case splitView

    public static var slotTitle: String { "Feed Navigation" }

    public static var fallback: AppNavigationDesign { .plain }

    public var displayName: String {
        switch self {
        case .plain: return "Plain"
        case .splitView: return "Split View"
        }
    }

    public var isAvailableOnThisDevice: Bool {
        switch self {
        case .plain:
            return true
        case .splitView:
            // Two columns in a phone-width window collapse to one, which is just `.plain`
            // with extra steps.
            return UIDevice.current.userInterfaceIdiom == .pad
        }
    }
}
