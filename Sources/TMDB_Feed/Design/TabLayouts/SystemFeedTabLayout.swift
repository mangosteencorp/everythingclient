import SwiftUI

/// The system `TabView`. iPad only — see `FeedTabDesign.isAvailableOnThisDevice`.
@available(iOS 16, *)
struct SystemFeedTabLayout<Content: View>: View {
    let tabs: [FeedTab]
    @Binding var selection: FeedTab
    @Binding var visibleTab: FeedTab
    @ViewBuilder let content: (FeedTab) -> Content

    @ViewBuilder
    var body: some View {
        // There are more tabs than the tab bar can show, so iOS moves the overflow
        // into its "More" list. The legacy `.tabItem` bridge renders those overflow
        // tabs into a detached controller that never redraws, so they stay frozen on
        // whatever was on screen when the More list was built (an empty feed showing
        // "No Results Found"). The iOS 18 `Tab` API keeps them live.
        #if os(iOS)
        if #available(iOS 26, *) {
            TabView(selection: $selection) {
                ForEach(tabs) { tab in
                    Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                        tabRoot(for: tab)
                    }
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
        } else if #available(iOS 18, *) {
            TabView(selection: $selection) {
                ForEach(tabs) { tab in
                    Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                        tabRoot(for: tab)
                    }
                }
            }
        } else {
            legacyTabView
        }
        #else
        // This layout is iPad-only (`FeedTabDesign.isAvailableOnThisDevice`), so macOS never
        // selects it; the legacy branch just keeps the file compiling. A bare `*` in the
        // `#available` clauses above matches macOS, hence the `#if`.
        legacyTabView
        #endif
    }

    /// The `tabItem`-based `TabView`, which every supported OS understands.
    private var legacyTabView: some View {
        TabView(selection: $selection) {
            ForEach(tabs) { tab in
                tabRoot(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
    }

    private func tabRoot(for tab: FeedTab) -> some View {
        // iOS never updates the `selection` binding for tabs opened from the More list,
        // so the visible tab has to be tracked from the content itself to keep the
        // navigation title in sync.
        content(tab)
            .onAppear { visibleTab = tab }
    }
}
