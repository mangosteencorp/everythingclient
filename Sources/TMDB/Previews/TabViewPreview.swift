import SwiftUI
#if DEBUG
#Preview {
    TMDBPreviewCatalog.tabsNormal.view
}

#Preview("page style") {
    TMDBPreviewCatalog.tabsPage.view
}

#Preview("floating bar") {
    TMDBPreviewCatalog.floatingBarDesign.view
}

#Preview("sidebar tab bar (iPad, iOS 27)") {
    TMDBPreviewCatalog.sidebarTabBarDesign.view
}

#Preview("sectioned sidebar") {
    TMDBPreviewCatalog.sectionedSidebarDesign.view
}

#Preview("Tab contain TMDBAPITabView") {
    TMDBPreviewCatalog.tabsEmbedded.view
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
#endif
