import SwiftUI
import TMDB
import Pokedex
import AppCore
public struct RootContentView: View {
    @StateObject private var tabManager = TabManager.shared
    @State private var selectedTab = 0
    let tmdbAPIKey: String
    private let isAppStoreOrTestFlight: Bool
    
    public init(TMDBApiKey: String, isAppStoreOrTestFlight: Bool = true) {
        self.tmdbAPIKey = TMDBApiKey
        self.isAppStoreOrTestFlight = isAppStoreOrTestFlight
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(tabManager.availableTabs)) { tab in
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
        
        .onAppear {
            tabManager.availableTabs = isAppStoreOrTestFlight ? Set([.tmdb]) : Set(AppTab.allCases)
        }
    }
}
