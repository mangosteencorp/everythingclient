// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import SwiftUI
import Swinject
import TMDB_Shared_Backend

#if DEBUG
@available(iOS 16, *)
public struct TMDBDiscoverDemoView: View {
    private let container: Container

    public init() {
        let container = Container()
        TMDB_Shared_Backend.configure(container: container, apiKey: debugTMDBAPIKey)
        self.container = container
    }

    public var body: some View {
        TabView {
            TabView {
                NavigationStack {
                    DiscoverListPage(
                        container: container,
                        apiKey: debugTMDBAPIKey,
                        type: .airingToday,
                        detailRouteBuilder: { _, _ in 1 })
                    .tag(0)
                    .tabItem {
                        Label("First View", systemImage: "house")
                    }
                }
                Text("Second View").tag(1)
                    .tabItem {
                        Label("Second View", systemImage: "gear")
                    }
            }
            .tag(0)
            .tabItem {
                Label("Outer First View", systemImage: "star")
            }
            Text("Outer Second View").tag(1)
                .tabItem {
                    Label("Outer Second View", systemImage: "moon")
                }
        }
    }
}

@available(iOS 16, *)
#Preview {
    TMDBDiscoverDemoView()
}

#endif
#endif
