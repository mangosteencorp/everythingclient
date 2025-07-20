import SwiftUI
import TMDB_Shared_Backend
#if DEBUG
@available(iOS 16, macOS 10.15, *)
#Preview {
    TabView {
        TabView {
            NavigationSplitView {
                MovieFeedListPage(
                    apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
                    detailRouteBuilder: { _ in 1 },
                    tvShowDetailRouteBuilder: { _ in 1 }
                )
                .navigationTitle("Movies")
                .tag(0)
                .tabItem {
                    Label("First View", systemImage: "house")
                }

            } detail: {
                Text("Select a movie to see details")
                    .navigationTitle("Detail")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationSplitViewStyle(.balanced)
            .preferredColorScheme(.dark)

            Text("Second View")
                .tag(1)
                .tabItem {
                    Label("Second View", systemImage: "gear")
                }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
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

@available(iOS 16, macOS 10.15, *)
#Preview("Simple Navigation") {
    NavigationSplitView {
        MovieFeedListPage(
            apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
            detailRouteBuilder: { _ in 1 }, tvShowDetailRouteBuilder: { _ in 1 }
        )
        .navigationTitle("Movies")

    } detail: {
        Text("Select a movie to see details")
            .navigationTitle("Detail")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .navigationSplitViewStyle(.balanced)
}
#endif
