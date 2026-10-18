import SwiftUI
import TMDB_Search

@main
struct TMDBSearchDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List(TMDBSearchPreviewCatalog.allCases, id: \.self) { preview in
                    NavigationLink(preview.rawValue) {
                        preview.view
                    }
                }
            }
        }
    }
}
