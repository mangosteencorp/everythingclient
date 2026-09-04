import SwiftUI

/// Full-bleed horizontally swipeable pages with a dot indicator instead of a bar.
@available(iOS 16, *)
struct PagedTabShell<Page: View>: View {
    @ObservedObject var coordinator: Coordinator
    @ViewBuilder let page: (TabRoute) -> Page

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ForEach(coordinator.tabList, id: \.self) { tab in
                page(tab)
                    .tag(tab)
            }
        }
        // `PageTabViewStyle` is iOS/tvOS/watchOS only. On macOS this degrades to a plain
        // `TabView`; `AppShellDesign.isAvailableOnThisDevice` keeps the option out of the
        // design picker there so the degraded state is never user-selectable.
        #if os(iOS)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        #endif
    }
}
