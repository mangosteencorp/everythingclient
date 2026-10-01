import CoreFeatures
import SwiftUI

/// System `TabView`, either with the standard bar or promoted to a sidebar on iPad.
@available(iOS 16, *)
struct SystemTabShell<Page: View>: View {
    @ObservedObject var coordinator: Coordinator
    let usesSidebarPlacement: Bool
    @ViewBuilder let page: (TabRoute) -> Page

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ForEach(coordinator.tabList, id: \.self) { tab in
                // `role: .search` plus `searchTabActivatesSearch()` is what detaches the search
                // tab from the bar on iOS 26+ and turns it into the page's search field.
                Tab(tab.title, systemImage: tab.iconName, value: tab, role: tab == .search ? .search : nil) {
                    page(tab)
                }
                .accessibilityIdentifier(tab.customizationID)
            }
        }
        .searchTabActivatesSearch()
        .withDefaultSidebarTabBarPlacement(enabled: usesSidebarPlacement)
    }
}

@available(iOS 16, *)
private extension View {
    @ViewBuilder
    func withDefaultSidebarTabBarPlacement(enabled: Bool) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27, *), enabled {
            defaultTabBarPlacement(.sidebar)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

#if DEBUG
@available(iOS 16, *)
#Preview("Tab bar") {
    SystemTabShell(coordinator: .preview, usesSidebarPlacement: false) { ShellPagePreview(title: $0.title) }
}

@available(iOS 16, *)
#Preview("Sidebar placement (iPad, iOS 27)") {
    SystemTabShell(coordinator: .preview, usesSidebarPlacement: true) { ShellPagePreview(title: $0.title) }
}
#endif
