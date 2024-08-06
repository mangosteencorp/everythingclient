import SwiftUI
import TMDB
public struct RootContentView: View {
    @State private var selectedTab = 0
    let tmdbAPIKey: String
    public init(TMDBApiKey: String) {
        tmdbAPIKey = TMDBApiKey
    }
    public var body: some View {
        TabView(selection: $selectedTab){
            if #available(iOS 15, *) {
                TMDBAPITabView(tmdbKey: tmdbAPIKey)
                    .tabItem {
                        Label(
                            title: { Text("TMDB") },
                            icon: { Image(systemName: "movieclapper") }
                        )
                    }
            } 
            Text("GitHub API")
                .tabItem { Label("GitHub API", systemImage: "desktopcomputer") }
        }
    }
}

#Preview {
    RootContentView(TMDBApiKey: <#T##String#>)
}
