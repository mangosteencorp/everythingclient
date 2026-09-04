import SwiftUI

/// Custom pill bar floating above the content, hidden once a tab pushes a detail page.
@available(iOS 16, *)
struct FloatingTabShell<Page: View>: View {
    @ObservedObject var coordinator: Coordinator
    @ViewBuilder let page: (TabRoute) -> Page

    var body: some View {
        let tabItems = coordinator.tabList.map { tab in
            FloatingTabItem(tag: tab, icon: Image(systemName: tab.iconName), title: tab.title)
        }

        ZStack(alignment: .bottom) {
            // Only the selected tab is built: the floating bar is not a `TabView`, so there is
            // no system container keeping the others alive.
            page(coordinator.selectedTab)

            FloatingTabBar(selection: $coordinator.selectedTab, isHidden: Binding(
                get: { coordinator.tabBarHiddenStates[coordinator.selectedTab] ?? false },
                set: { _ in }
            ), items: tabItems)
        }
    }
}
