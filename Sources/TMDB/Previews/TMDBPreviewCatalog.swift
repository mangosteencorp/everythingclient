#if DEBUG
import CoreFeatures
import PhotoListViewer
import SwiftUI
import Swinject
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// Every app shell preview as a view of its own, so Xcode's canvas, the integration launcher and
/// the screenshot run all render the same thing.
///
/// The `tabs…` and `…Design` cases are the whole TMDB app, loading live from TMDB; the `…Design`
/// ones pick their shell in the shared `DesignCoordinator`, which saves it like any other design
/// choice. The `…Shell` cases show only a shell's own chrome around placeholder pages.
public enum TMDBPreviewCatalog: String, CaseIterable {
    case tabsNormal
    case tabsPage
    case tabsEmbedded
    case floatingBarDesign
    case sidebarTabBarDesign
    case sectionedSidebarDesign
    case systemTabShell
    case systemTabShellSidebar
    case floatingTabShell
    case pagedTabShell
    case sectionedSidebarShell
    case floatingTabBar
    case pageDots
    case splitDetailPlaceholder
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
        case .sectionedSidebarDesign:
            ShellPreview(design: .sectionedSidebar)
        default:
            shell
        }
    }

    @MainActor @ViewBuilder
    private var shell: some View {
        switch self {
        case .systemTabShell, .systemTabShellSidebar:
            SystemTabShell(coordinator: .preview, usesSidebarPlacement: self == .systemTabShellSidebar) {
                ShellPagePreview(title: $0.title)
            }
        case .floatingTabShell:
            FloatingTabShell(coordinator: .preview) { ShellPagePreview(title: $0.title) }
        case .pagedTabShell:
            PagedTabShell(coordinator: .preview) { ShellPagePreview(title: $0.title) }
        case .sectionedSidebarShell:
            SectionedSidebarShell(
                coordinator: .preview,
                page: { ShellPagePreview(title: $0.title) },
                // Feed pages come without a stack: the shell owns it.
                feedPage: { tab in List(1...20, id: \.self) { Text("\(tab.title) \($0)") }.navigationTitle(tab.title) }
            )
        default:
            widget
        }
    }

    @MainActor @ViewBuilder
    private var widget: some View {
        switch self {
        case .floatingTabBar:
            StatefulPreview(TabRoute.movieFeed) { selection in
                VStack {
                    Spacer()
                    FloatingTabBar(
                        selection: selection,
                        isHidden: .constant(false),
                        items: Coordinator.preview.tabList.map {
                            FloatingTabItem(
                                tag: $0,
                                icon: Image(systemName: $0.iconName),
                                title: $0.title,
                                accessibilityIdentifier: $0.customizationID
                            )
                        }
                    )
                }
            }
        case .pageDots:
            StatefulPreview(1) { PageDots(currentPage: $0, numberOfPages: 5) }
                .padding()
        case .splitDetailPlaceholder:
            FeedSplitDetailPlaceholder()
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
        default:
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
            .onAppear { DesignCoordinator.shared.select(design) }
    }
}
#endif
