import CoreFeatures
import SwiftUI
import Swinject
import TMDB_Feed

/// The `.splitView` shell's feed tab: the feed list on the left, the selected title on the right.
@available(iOS 16, *)
struct FeedSplitView: ViewModifier {
    let container: Container

    /// Split view drives its detail column from selection, not from links — see
    /// `FeedNavigationMode` for why value links cannot work across columns.
    @State private var selectedRoute: AnyHashable?
    @State private var detailPath = NavigationPath()

    func body(content: Content) -> some View {
        // Pinned open: the tab sidebar already has the one toggle, so this column gets none.
        NavigationSplitView(columnVisibility: .constant(.all)) {
            content
                .feedSelectionNavigation($selectedRoute)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            // The destination modifier belongs to *this* stack: it is what the detail
            // column pushes onto once you drill in from the selected title.
            NavigationStack(path: $detailPath) {
                detailRoot
                    .withTMDBNavigationDestinations(container: container)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selectedRoute) {
            // A new selection replaces the column, so anything pushed on top of the
            // previous one is stale.
            detailPath = NavigationPath()
        }
    }

    @ViewBuilder
    private var detailRoot: some View {
        if let route = selectedRoute as? TMDBRoute {
            TMDBRouteView(route: route, container: container)
                // Without an identity tied to the route, SwiftUI reuses the previous detail
                // root and the column appears frozen on the first selection.
                .id(route)
        } else {
            FeedSplitDetailPlaceholder()
        }
    }
}

@available(iOS 16, *)
struct FeedSplitDetailPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "film")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(L10nFeedSelect.title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(L10nFeedSelect.prompt)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("feed.split.detail.placeholder")
    }
}

/// Local strings for the split-detail placeholder (TMDB module may not import TMDB_Feed L10n).
private enum L10nFeedSelect {
    static let title = "Select a title"
    static let prompt = "Choose a movie or TV show to see details."
}

@available(iOS 16, *)
extension View {
    func withFeedSplitView(container: Container) -> some View {
        modifier(FeedSplitView(container: container))
    }
}

#if DEBUG
#Preview("Split view detail placeholder") {
    FeedSplitDetailPlaceholder()
}
#endif
