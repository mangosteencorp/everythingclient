#if DEBUG
import CoreFeatures
import PhotoListViewer
import SwiftUI
import Swinject
import TMDB_Feed
import TMDB_Shared_Backend

/// Every app shell preview as a view of its own, so Xcode's canvas, the integration launcher and
/// the screenshot run all render the same thing.
///
/// The `tabs…` and `…Design` cases are the whole TMDB app, loading live from TMDB; the `…Design`
/// ones pin their shell with `.designStyle(_:)`, so previewing one never rewrites the saved choice.
public enum TMDBPreviewCatalog: String, CaseIterable, Identifiable {
    public var id: String {
        return rawValue
    }
    case tabsNormal
    case tabsPage
    case tabsEmbedded
    case floatingBarDesign
    case sidebarTabBarDesign
    case splitViewDesign
    case sectionedSidebarDesign
    case feedTabsPage
    case photoSlidesRoute
    case settings

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .tabsNormal:
            TMDBAPITabView(tmdbKey: debugTMDBAPIKey, tabStyle: .normal)
        case .tabsPage:
            TMDBAPITabView(tmdbKey: debugTMDBAPIKey, tabStyle: .page)
        case .tabsEmbedded:
            TabView {
                TMDBAPITabView(tmdbKey: debugTMDBAPIKey)
                    .tabItem {
                        Label("TMDB", systemImage: "film")
                    }
            }
        case .floatingBarDesign:
            ShellPreview(design: .floatingTabBar)
        case .sidebarTabBarDesign:
            ShellPreview(design: .sidebarTabBar)
        case .splitViewDesign:
            ShellPreview(design: .splitView)
        case .sectionedSidebarDesign:
            ShellPreview(design: .sectionedSidebar)
        case .feedTabsPage:
            NavigationStack {
                FeedTabsPage(
                    apiService: PreviewFeedAPIService(),
                    detailRouteBuilder: { $0.id },
                    tvShowDetailRouteBuilder: { $0.id }
                )
            }
        case .photoSlidesRoute:
            // Photo slides resolve nothing from the container, so an empty one is enough.
            NavigationStack {
                TMDBRouteView(
                    route: .photoSlides(PhotoSlidesRouteModel(
                        imagePaths: ["/AvIfrjJL9WRk3TziSvOZCTUHKEn.jpg", "/1ffZAucqfvQu36x1C49XfOdjuOG.jpg"],
                        initialIndex: 0
                    )),
                    container: Container()
                )
            }
        case .settings:
            SettingsPageView()
        }
    }
}

/// Any `AppShellDesign`, including the ones the legacy `TabStyle` seed has no case for. Every
/// shell offers the Search tab.
private struct ShellPreview: View {
    let design: AppShellDesign

    var body: some View {
        TMDBAPITabView(tmdbKey: debugTMDBAPIKey)
            .designStyle(design)
    }
}
#endif
