import SwiftUI

/// Semantic background colours, bridged across UIKit and AppKit.
///
/// SwiftUI exposes `Color.primary`/`.secondary` on every platform, but the *grouped background*
/// family only exists as `UIColor` constants. AppKit's nearest equivalents are the window and
/// control background colours, which track the same light/dark and accessibility settings.
public extension Color {
    /// Page background behind grouped content.
    static var platformGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(.systemGroupedBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }

    /// Background of a card or row sitting on `platformGroupedBackground`.
    static var platformSecondaryGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(.secondarySystemGroupedBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    /// Background of content nested one level inside a card.
    static var platformTertiaryGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(.tertiarySystemGroupedBackground)
        #else
        return Color(nsColor: .underPageBackgroundColor)
        #endif
    }

    /// Background of a control or chip sitting on the plain page background.
    static var platformSecondaryBackground: Color {
        #if canImport(UIKit)
        return Color(.secondarySystemBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
}
