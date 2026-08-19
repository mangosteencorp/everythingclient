import CoreFeatures
import SwiftUI

/// Hosts the inner feed tabs, delegating all chrome to the current `FeedTabDesign`.
///
/// Owns nothing but the switch: selection, data loading and content stay with the page, so a
/// new layout never has to know what a feed is.
@available(iOS 16, *)
struct FeedTabContainer<Content: View>: View {
    let tabs: [FeedTab]
    @Binding var selection: FeedTab
    /// What is actually on screen. Diverges from `selection` only in `.systemTabs`, where iOS
    /// opens overflow tabs without updating the selection binding.
    @Binding var visibleTab: FeedTab
    @ViewBuilder let content: (FeedTab) -> Content

    @DesignStyle private var design: FeedTabDesign

    var body: some View {
        switch design {
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
