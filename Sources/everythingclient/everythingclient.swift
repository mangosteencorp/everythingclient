import SwiftUI
import TMDB
import Pokedex

public struct RootContentView: View {
    @State private var selectedTab = 0
    let tmdbAPIKey: String
    
    public init(TMDBApiKey: String) {
        tmdbAPIKey = TMDBApiKey
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            if #available(iOS 16, *) {
                TMDBAPITabView(tmdbKey: tmdbAPIKey)
                    .tabItem {
                        Label(
                            title: { Text("TMDB") },
                            icon: { Image(systemName: "movieclapper") }
                        )
                    }
                    .tag(0)
            }
            
            PokedexTabView()
                .tabItem {
                    Label("Pokédex", systemImage: "sparkles")
                }
                .tag(1)
            
            
        }
    }
}

#Preview {
    RootContentView(TMDBApiKey: "")
}
