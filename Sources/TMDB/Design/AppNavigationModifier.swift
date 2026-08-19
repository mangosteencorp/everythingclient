import CoreFeatures
import SwiftUI
import Swinject
import TMDB_Feed

/// Wraps the feed tab in whatever navigation container `AppNavigationDesign` asks for.
@available(iOS 16, *)
struct AppNavigationModifier: ViewModifier {
    let design: AppNavigationDesign
    let coordinator: Coordinator
    let tabRoute: TabRoute
    let container: Container

    /// Split view drives its detail column from selection, not from links — see
    /// `FeedNavigationMode` for why value links cannot work across columns.
    @State private var selectedRoute: AnyHashable?
    @State private var detailPath = NavigationPath()

    func body(content: Content) -> some View {
        switch design {
        case .plain:
            NavigationStack(path: coordinator.path(for: tabRoute)) {
                content
                    .withTMDBNavigationDestinations(container: container)
            }
        case .splitView:
            NavigationSplitView {
                content
                    .feedSelectionNavigation($selectedRoute)
            } detail: {
                // The destination modifier belongs to *this* stack: it is what the detail
                // column pushes onto once you drill in from the selected title.
                NavigationStack(path: $detailPath) {
                    detailRoot
                        .withTMDBNavigationDestinations(container: container)
                }
            }
            .navigationSplitViewStyle(.balanced)
            .onChange(of: selectedRoute) { _ in
                // A new selection replaces the column, so anything pushed on top of the
                // previous one is stale.
                detailPath = NavigationPath()
            }
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
private struct FeedSplitDetailPlaceholder: View {
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
    func withAppNavigationDesign(
        _ design: AppNavigationDesign,
        coordinator: Coordinator,
        tabRoute: TabRoute,
        container: Container
    ) -> some View {
        modifier(AppNavigationModifier(
            design: design,
            coordinator: coordinator,
            tabRoute: tabRoute,
            container: container
        ))
    }
}
