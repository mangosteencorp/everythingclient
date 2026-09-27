import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
#if DEBUG
import TMDB_Shared_Backend
@available(iOS 16, *)
#Preview {
    TMDBAPITabView(tmdbKey: debugTMDBAPIKey, tabStyle: .normal)
}

@available(iOS 16, *)
#Preview("page style") {
    TMDBAPITabView(tmdbKey: debugTMDBAPIKey, tabStyle: .page)
}

@available(iOS 16, *)
#Preview("floating bar") {
    ShellPreview(design: .floatingTabBar)
}

@available(iOS 16, *)
#Preview("sidebar tab bar (iPad, iOS 27)") {
    ShellPreview(design: .sidebarTabBar)
}

@available(iOS 16, *)
#Preview("sectioned sidebar") {
    ShellPreview(design: .sectionedSidebar)
}

@available(iOS 16, *)
#Preview("Tab contain TMDBAPITabView") {
    TabView {
        TMDBAPITabView(tmdbKey: debugTMDBAPIKey)
            .tabItem {
                Label("TMDB", systemImage: "film")
            }
    }
}

/// Any `AppShellDesign`, including the ones the legacy `TabStyle` seed has no case for. Every
/// shell offers the Search tab.
@available(iOS 16, *)
private struct ShellPreview: View {
    let design: AppShellDesign

    var body: some View {
        TMDBAPITabView(tmdbKey: debugTMDBAPIKey)
            .onAppear { DesignCoordinator.shared.select(design) }
    }
}
#endif
