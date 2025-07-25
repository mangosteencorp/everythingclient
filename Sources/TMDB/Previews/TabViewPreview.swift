import SwiftUI
import TMDB_Shared_Backend
#if DEBUG
import TMDB_Shared_Backend
@available(iOS 16, *)
#Preview {
    TMDBAPITabView(tmdbKey: debugTMDBAPIKey, tabStyle: .normal)
}

@available(iOS 16, *)
#Preview("page style") {
    TMDBAPITabView(tmdbKey: debugTMDBAPIKey, tabStyle: .page)
}

@available(iOS 16, *)
#Preview("Tab contain TMDBAPITabView") {
    TabView {
        TMDBAPITabView(tmdbKey: debugTMDBAPIKey)
            .tabItem {
                Label("TMDB", systemImage: "film")
            }
    }
}
#endif
