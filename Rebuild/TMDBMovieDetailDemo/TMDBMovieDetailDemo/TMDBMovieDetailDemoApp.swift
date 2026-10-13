
import SwiftUI
import TMDB_MovieDetail
@main
struct TMDBMovieDetailDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                NavigationLink("Detail Page") {
                    TMDBMovieDetailPreviewCatalog.detailPage.view
                }
            }
        }
        
    }
}
