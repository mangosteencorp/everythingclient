
import SwiftUI
import TMDB_MovieDetail
@main
struct TMDBMovieDetailDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                VStack {
                    
                    NavigationLink("Demo") {
                        TMDBMovieDetailPreviewCatalog.demo.view
                    }
                    
                    NavigationLink("Detail Page") {
                        TMDBMovieDetailPreviewCatalog.detailPage.view
                    }
                    
                }
            }
            
            
        }
        
    }
}
