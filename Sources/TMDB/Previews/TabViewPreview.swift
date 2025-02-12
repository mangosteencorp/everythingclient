import SwiftUI

#if DEBUG
@available(iOS 16,*)
#Preview {
    TMDBAPITabView(tmdbKey: "YOUR_API_KEY")
}

@available(iOS 16,*)
#Preview("Tab contain TMDBAPITabView") {
    TabView {
        TMDBAPITabView(tmdbKey: "YOUR_API_KEY")
            .tabItem {
                Label("TMDB", systemImage: "film")
            }
    }
}
#endif
