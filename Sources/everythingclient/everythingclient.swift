import SwiftUI
import TMDB
import Pokedex

public enum AppTab: Int, CaseIterable, Identifiable {
    
    case tmdb = 0
    case pokedex = 1
    
    public var id: Int { rawValue }
    
    var label: (String, String) {
        switch self {
        case .tmdb:
            return ("TMDB", "movieclapper")
        case .pokedex:
            return ("Pokédex", "sparkles")
        }
    }
}

public struct RootContentView: View {
    @State private var selectedTab = 0
    let tmdbAPIKey: String
    let availableTabs: Set<AppTab>
    
    public init(TMDBApiKey: String, availableTabs: Set<AppTab> = Set(AppTab.allCases)) {
        self.tmdbAPIKey = TMDBApiKey
        self.availableTabs = availableTabs
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(availableTabs)) { tab in
                switch tab {
                case .tmdb:
                    if #available(iOS 16, *) {
                        TMDBAPITabView(tmdbKey: tmdbAPIKey)
                            .tabItem {
                                Label(tab.label.0, systemImage: tab.label.1)
                            }
                            .tag(tab.rawValue)
                    }
                case .pokedex:
                    PokedexTabView()
                        .tabItem {
                            Label(tab.label.0, systemImage: tab.label.1)
                        }
                        .tag(tab.rawValue)
                }
            }
        }
    }
}

#Preview {
    RootContentView(TMDBApiKey: "", availableTabs: [.pokedex]) // Example showing only Pokedex tab
}
