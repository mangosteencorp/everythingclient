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

/// The root tabs `TMDBAPITabView` hands every shell, for previewing a shell on its own.
@available(iOS 16, *)
extension Coordinator {
    static var preview: Coordinator {
        Coordinator(tabList: [.movieFeed, .marketplace, .profile, .settings, .search])
    }
}

/// Stands in for a real tab, so a shell preview shows only the shell's own chrome and needs no
/// network.
@available(iOS 16, *)
struct ShellPagePreview: View {
    let title: String

    var body: some View {
        NavigationStack {
            List(1...20, id: \.self) { Text("\(title) \($0)") }
                .navigationTitle(title)
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
