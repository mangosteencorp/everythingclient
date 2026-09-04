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
                page(tab)
                    .tabItem {
                        Image(systemName: tab.iconName)
                        Text(tab.title)
                    }
                    .tag(tab)
            }
        }
        .withDefaultSidebarTabBarPlacement(enabled: usesSidebarPlacement)
    }
}

@available(iOS 16, *)
private extension View {
    @ViewBuilder
    func withDefaultSidebarTabBarPlacement(enabled: Bool) -> some View {
        // `os(iOS)` as well as the compiler gate: `AdaptableTabBarPlacement.sidebar` is explicitly
        // unavailable on macOS, and `anyAppleOS 27` matches macOS 27, so the availability check
        // alone lets this through on a Mac build. `AppShellDesign.isAvailableOnThisDevice` already
        // keeps `.sidebarTabBar` off macOS (it requires `PlatformIdiom.isPad`), so nothing is lost.
        #if compiler(>=6.4) && os(iOS)
        if #available(anyAppleOS 27, *), enabled {
            defaultTabBarPlacement(.sidebar)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
