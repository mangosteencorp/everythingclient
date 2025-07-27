import SwiftUI
import Swinject
import TMDB_Shared_Backend

#if DEBUG
@available(iOS 16, *)
public struct TMDBDiscoverDemoView: View {
    public init() {}

    public var body: some View {
        TabView {
            TabView {
                NavigationStack {
                    TVShowListPage(
                        container: Container(),
                        apiKey: debugTMDBAPIKey,
                        type: .airingToday,
                        detailRouteBuilder: { _ in 1 })
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

#if DEBUG
@available(iOS 16, *)
#Preview {
    TMDBDiscoverDemoView()
}
#endif
#endif