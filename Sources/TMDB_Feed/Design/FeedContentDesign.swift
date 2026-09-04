import CoreFeatures
import SwiftUI

/// How the items *inside* one feed are laid out.
///
/// Adding a layout is one case here plus one arm in `FeedItemsView`.
public enum FeedContentDesign: String, DesignVariant {
    /// Poster, title, rating and a three-line overview — the original feed row.
    case list
    /// Poster grid, title underneath.
    case grid
    /// Thumbnail, title, rating on one line — many more titles per screen.
    case compactRows

    public static var slotTitle: String { "Feed Content" }

    public static var fallback: FeedContentDesign { .list }

    public var displayName: String {
        switch self {
        case .list: return "List"
        case .grid: return "Grid"
        case .compactRows: return "Compact Rows"
        }
    }
}

/// Whether an empty feed uses the animated empty state or the plain one.
public enum FeedEmptyStateDesign: String, DesignVariant {
    case fancy
    case plain

    public static var slotTitle: String { "Empty State" }

    public static var fallback: FeedEmptyStateDesign { .fancy }

    public var displayName: String {
        switch self {
        case .fancy: return "Fancy"
        case .plain: return "Plain"
        }
    }
}
