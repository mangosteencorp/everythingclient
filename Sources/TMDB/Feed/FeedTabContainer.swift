import CoreFeatures
import SwiftUI
import TMDB_Feed
import TMDB_Shared_UI

/// Hosts the inner feed tabs, delegating all chrome to the current `FeedTabDesign`.
///
/// Owns nothing but the switch: selection, data loading and content stay with the page, so a
/// new layout never has to know what a feed is.
@available(iOS 16, *)
struct FeedTabContainer<Content: View>: View {
    let tabs: [FeedKind]
    @Binding var selection: FeedKind
    /// What is actually on screen. Diverges from `selection` only in `.systemTabs`, where iOS
    /// opens overflow tabs without updating the selection binding.
    @Binding var visibleTab: FeedKind
    @ViewBuilder let content: (FeedKind) -> Content

    @DesignStyle private var design: FeedTabDesign
    @Environment(\.feedNavigationMode) private var navigationMode

    /// A split-view sidebar column is too narrow for a second `TabView`: its bar drops to the
    /// column's bottom edge and its insets stack under the column's nav bar.
    private var effectiveDesign: FeedTabDesign {
        if case .select = navigationMode { return .topSegments }
        return design
    }

    var body: some View {
        switch effectiveDesign {
        case .systemTabs:
            SystemFeedTabLayout(
                tabs: tabs,
                selection: $selection,
                visibleTab: $visibleTab,
                content: content
            )
        case .topSegments:
            TopSegmentsFeedTabLayout(
                tabs: tabs,
                selection: $selection,
                visibleTab: $visibleTab,
                content: content
            )
        }
    }
}

#if DEBUG
#Preview("Feed Tabs — Design switch") {
    NavigationStack {
        StatefulPreview(FeedKind.nowPlaying) { selection in
            StatefulPreview(FeedKind.nowPlaying) { visibleTab in
                FeedTabContainer(tabs: FeedKind.allCases, selection: selection, visibleTab: visibleTab) { Text($0.title) }
            }
        }
        .toolbar {
            DesignShuffleToolbarItem()
        }
    }
}
#endif
