import CoreFeatures
import SwiftUI
import TMDB

public struct RootContentView: View {
    @ObservedObject private var tabManager = TabManager.shared
    @State private var selectedTab = 0
    let tmdbAPIKey: String
    private let isAppStoreOrTestFlight: Bool
    private let initialTabs: Set<AppTab>
    private let analyticsTracker: AnalyticsTracker?

    public init(TMDBApiKey: String, isAppStoreOrTestFlight: Bool = true, options3rdPartySDKs: ThirdPartyInitializationOptions = .init()) {
        tmdbAPIKey = TMDBApiKey
        self.isAppStoreOrTestFlight = isAppStoreOrTestFlight
        initialTabs = isAppStoreOrTestFlight ? Set([.tmdb]) : Set(AppTab.allCases)
        analyticsTracker = options3rdPartySDKs.firebase ? FirebaseAnalyticsTracker() : nil
        TabManager.shared.availableTabs = initialTabs
    }

    public var body: some View {
        Group {
            if tabManager.availableTabs.count > 1 {
                tabViewContent
            } else {
                singleTabContent
            }
        }
        .onAppear {
            if tabManager.availableTabs != initialTabs {
                tabManager.availableTabs = initialTabs
            }
        }
    }

    @ViewBuilder
    private var tabViewContent: some View {
        if #available(iOS 26, *) {
            // iOS 26: New Liquid Glass tab bar with minimize behavior
            TabView(selection: $selectedTab) {
                ForEach(Array(tabManager.availableTabs)) { tab in
                    Tab(tab.label.0, systemImage: tab.label.1, value: tab.rawValue) {
                        tabContent(for: tab)
                    }
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            // Fallback for older iOS versions
            TabView(selection: $selectedTab) {
                ForEach(Array(tabManager.availableTabs)) { tab in
                    tabContent(for: tab)
                        .tabItem {
                            Label(tab.label.0, systemImage: tab.label.1)
                        }
                        .tag(tab.rawValue)
                }
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .tmdb:
            if #available(iOS 16, *) {
                TMDBAPITabView(
                    tmdbKey: tmdbAPIKey,
                    navigationInterceptor: TabManager.shared,
                    analyticsTracker: analyticsTracker
                )
            }
        }
    }

    @ViewBuilder
    private var singleTabContent: some View {
        if let singleTab = tabManager.availableTabs.first {
            switch singleTab {
            case .tmdb:
                if #available(iOS 16, *) {
                    TMDBAPITabView(
                        tmdbKey: tmdbAPIKey,
                        tabStyle: .normal,
                        navigationInterceptor: TabManager.shared,
                        analyticsTracker: analyticsTracker
                    )
                }
            }
        }
    }
}
