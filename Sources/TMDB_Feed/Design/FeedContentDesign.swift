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
    /// Cards tinted with the poster's own average colour, 1–3 columns by width.
    case paletteCards

    public static var slotTitle: String { "Feed Content" }

    public static var fallback: FeedContentDesign { .list }

    public var displayName: String {
        switch self {
        case .list: return "List"
        case .grid: return "Grid"
        case .compactRows: return "Compact Rows"
        case .paletteCards: return "Palette Cards"
        }
    }
}
