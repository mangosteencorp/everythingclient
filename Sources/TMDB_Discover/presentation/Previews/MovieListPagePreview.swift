import SwiftUI
import Swinject
import TMDB_Shared_Backend
#if DEBUG

@available(iOS 16, macOS 10.15, *)
#Preview("airing today page within nested tab view") {
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
        //.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
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
#endif
