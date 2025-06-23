import SwiftUI
import TMDB_Shared_Backend
#if DEBUG
import TMDB_Shared_Backend
@available(iOS 16, *)
#Preview {
    TMDBAPITabView(tmdbKey: debugTMDBAPIKey)
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
