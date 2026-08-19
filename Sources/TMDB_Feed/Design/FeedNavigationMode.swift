import SwiftUI

/// How a feed row hands its route to whatever is hosting the feed.
///
/// A `NavigationLink(value:)` needs a `navigationDestination` inside the stack it targets. In a
/// `NavigationSplitView` the feed lives in the sidebar column and the destination belongs to the
/// *detail* column's stack, so value links there resolve against the sidebar's own implicit stack
/// and stop updating after the first tap. Selection avoids the ambiguity entirely.
public enum FeedNavigationMode {
    /// Rows push onto the enclosing `NavigationStack`. Default.
    case push
    /// Rows write their route into a binding the host reads to build another column.
    case select(Binding<AnyHashable?>)
}

private struct FeedNavigationModeKey: EnvironmentKey {
    static let defaultValue: FeedNavigationMode = .push
}

public extension EnvironmentValues {
    var feedNavigationMode: FeedNavigationMode {
        get { self[FeedNavigationModeKey.self] }
        set { self[FeedNavigationModeKey.self] = newValue }
    }
}

public extension View {
    /// Makes every feed row inside this view report its route through `selection` instead of
    /// pushing. Used by the split-view and multi-column shells.
    func feedSelectionNavigation(_ selection: Binding<AnyHashable?>) -> some View {
        environment(\.feedNavigationMode, .select(selection))
    }
}

/// One tappable feed item, rendered as a push link or a selectable cell depending on the host.
/// Layout-neutral: `label` decides what a row/cell looks like.
///
/// In `.select` mode inside a `List`, the row is plain content carrying a `.tag`; the enclosing
/// `List(selection:)` owns the highlight. That is what lets a collapsed `NavigationSplitView`
/// clear the selection when the user taps Back — SwiftUI only does that for a real list
/// selection, never for a hand-rolled `Button`.
@available(iOS 16.0, *)
struct FeedRowLink<Route: Hashable, Label: View>: View {
    @Environment(\.feedNavigationMode) private var mode

    let route: Route
    /// Set for layouts that are not inside a selectable `List` (the grid), which have to drive
    /// the selection themselves.
    var drivesSelectionDirectly: Bool = false
    @ViewBuilder let label: () -> Label

    var body: some View {
        switch mode {
        case .push:
            NavigationLink(value: route) {
                label()
            }
        case .select(let selection):
            if drivesSelectionDirectly {
                Button {
                    selection.wrappedValue = AnyHashable(route)
                } label: {
                    label()
                        .background(
                            selection.wrappedValue == AnyHashable(route)
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                label()
            }
        }
    }
}
