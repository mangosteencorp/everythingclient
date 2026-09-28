import CoreFeatures
import SwiftUI
import TMDB_Feed
import TMDB_Search

/// Feed categories promoted out of the feed page and into the shell itself: sidebar sections on
/// iPad, one pushable list per section on iPhone, plus `TMDB_Search` as its own search-role tab.
///
/// All the `TabView` mechanics live in `SectionedTabView` (CoreFeatures). This file is only the
/// translation layer between that generic view and this app's `Coordinator`.
@available(iOS 18, *)
struct SectionedSidebarShell<Page: View, FeedPage: View>: View {
    @ObservedObject var coordinator: Coordinator
    /// Root tabs, already wrapped in their own `NavigationStack` by the caller.
    @ViewBuilder let page: (TabRoute) -> Page
    /// One feed category, *without* a `NavigationStack`: the shell owns the stack so the same
    /// page can also be pushed from the compact list.
    @ViewBuilder let feedPage: (FeedTab) -> FeedPage

    @State private var selection: ShellSelection<TabRoute, FeedTab> = .root(.marketplace)
    @Environment(\.horizontalSizeClass) private var sizeClass

    private static var roots: [TabRoute] { [.marketplace, .profile, .settings] }

    var body: some View {
        SectionedTabView(
            roots: Self.roots,
            sections: FeedTab.sections,
            searchRoot: .search,
            selection: $selection,
            customizationStorageKey: "tmdb.sectionedSidebar",
            rowPath: { coordinator.path(for: .feedRow($0)) },
            rootContent: { root in
                page(root).environment(\.searchPageFieldPlacement, fieldPlacement(for: root))
            },
            rowContent: { feedPage($0) },
            header: { Text(TabRoute.movieFeed.title).font(.title2.bold()) }
        )
        .onAppear { syncFromCoordinator() }
        .onChange(of: selection) { _, newValue in
            guard let tab = newValue.tabRoute else { return }
            coordinator.switchTab(to: tab)
        }
        // Keeps deep links and design switches in step. Guarded by `matches` so the compact
        // section selection is not rewritten into the row it resolves to, and back again.
        .onChange(of: coordinator.selectedTab) { _, newValue in
            guard !selection.matches(newValue) else { return }
            syncFromCoordinator()
        }
    }

    /// On iPhone the three roots, two sections and Search make six tabs, one more than a compact
    /// bar holds, so Search lands in "More" — and a search tab opened from there gets no field
    /// in the tab bar. Its page pins its own field under the title instead.
    private func fieldPlacement(for root: TabRoute) -> SearchFieldPlacement {
        root == .search && sizeClass == .compact ? .navigationBarDrawer(displayMode: .always) : .automatic
    }

    private func syncFromCoordinator() {
        if case let .feedRow(tab) = coordinator.selectedTab {
            selection = .row(tab)
        } else {
            selection = .root(coordinator.selectedTab)
        }
    }
}

@available(iOS 18, *)
private extension ShellSelection where Root == TabRoute, Row == FeedTab {
    /// The tab the coordinator should be on for this selection. A section has no route of its
    /// own, so it resolves to its first row.
    var tabRoute: TabRoute? {
        switch self {
        case let .root(route): return route
        case let .row(tab): return .feedRow(tab)
        case let .sectionList(id):
            guard let first = FeedTab.sections.first(where: { $0.id == id })?.rows.first else { return nil }
            return .feedRow(first)
        }
    }

    func matches(_ route: TabRoute) -> Bool {
        switch self {
        case let .root(root):
            return root == route
        case let .row(tab):
            return route == .feedRow(tab)
        case let .sectionList(id):
            guard case let .feedRow(tab) = route else { return false }
            return FeedTab.sections.first(where: { $0.id == id })?.rows.contains(tab) ?? false
        }
    }
}

#if DEBUG
@available(iOS 18, *)
#Preview {
    SectionedSidebarShell(
        coordinator: .preview,
        page: { ShellPagePreview(title: $0.title) },
        // Feed pages come without a stack: the shell owns it.
        feedPage: { tab in List(1...20, id: \.self) { Text("\(tab.title) \($0)") }.navigationTitle(tab.title) }
    )
}
#endif
