import CoreFeatures
import Pokedex
import SwiftUI
import TMDB
public struct RootContentView: View {
    @ObservedObject private var tabManager = TabManager.shared
    @State private var selectedTab = 0
    let tmdbAPIKey: String
    private let isAppStoreOrTestFlight: Bool
    private let analyticsTracker: AnalyticsTracker?

    public init(TMDBApiKey: String, isAppStoreOrTestFlight: Bool = true, options3rdPartySDKs: ThirdPartyInitializationOptions = .init()) {
        tmdbAPIKey = TMDBApiKey
        self.isAppStoreOrTestFlight = isAppStoreOrTestFlight
        analyticsTracker = options3rdPartySDKs.firebase ? FirebaseAnalyticsTracker() : nil
    }

    public var body: some View {
        Group {
            if tabManager.availableTabs.count > 1 {
                // Show TabView when multiple tabs are available
                TabView(selection: $selectedTab) {
                    ForEach(Array(tabManager.availableTabs)) { tab in
                        switch tab {
                        case .tmdb:
                            if #available(iOS 16, *) {
                                TMDBAPITabView(tmdbKey: tmdbAPIKey,
                                             navigationInterceptor: TabManager.shared,
                                             analyticsTracker: analyticsTracker)
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
            } else {
                // Show single tab content directly without TabView
                if let singleTab = tabManager.availableTabs.first {
                    switch singleTab {
                    case .tmdb:
                        if #available(iOS 16, *) {
                            TMDBAPITabView(tmdbKey: tmdbAPIKey,
                                           tabStyle: .normal,
                                         navigationInterceptor: TabManager.shared,
                                         analyticsTracker: analyticsTracker)
                        }
                    case .pokedex:
                        PokedexTabView()
                    }
                }
            }
        }
        .onAppear {
            tabManager.availableTabs = isAppStoreOrTestFlight ? Set([.tmdb]) : Set(AppTab.allCases)
        }
    }
}
