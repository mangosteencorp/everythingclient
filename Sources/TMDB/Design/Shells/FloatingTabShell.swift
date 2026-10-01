import SwiftUI

/// Custom pill bar floating above the content, hidden once a tab pushes a detail page.
@available(iOS 16, *)
struct FloatingTabShell<Page: View>: View {
    @ObservedObject var coordinator: Coordinator
    @ViewBuilder let page: (TabRoute) -> Page

    @State private var barHeight: CGFloat = 0

    private var isBarHidden: Bool {
        coordinator.tabBarHiddenStates[coordinator.selectedTab] ?? false
    }

    var body: some View {
        let tabItems = coordinator.tabList.map { tab in
            FloatingTabItem(
                tag: tab,
                icon: Image(systemName: tab.iconName),
                title: tab.title,
                accessibilityIdentifier: tab.customizationID
            )
        }

        ZStack(alignment: .bottom) {
            // Only the selected tab is built: the floating bar is not a `TabView`, so there is
            // no system container keeping the others alive.
            page(coordinator.selectedTab)
                // iOS 26+ puts a page's `.searchable` field in its bottom toolbar on iPhone, right
                // where this bar floats. Safe-area insets never reach that toolbar; a shorter page
                // does, and keeps the field clear of the bar.
                .padding(.bottom, coordinator.selectedTab == .search && !isBarHidden ? barHeight : 0)

            FloatingTabBar(selection: $coordinator.selectedTab, isHidden: Binding(
                get: { isBarHidden },
                set: { _ in }
            ), items: tabItems)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { barHeight = $0 }
        }
    }
}

#if DEBUG
@available(iOS 16, *)
#Preview {
    FloatingTabShell(coordinator: .preview) { ShellPagePreview(title: $0.title) }
}
#endif
