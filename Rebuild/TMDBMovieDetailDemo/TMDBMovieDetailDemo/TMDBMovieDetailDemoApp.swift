
import SwiftUI
import TMDB_MovieDetail
@main
struct TMDBMovieDetailDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                VStack {
                    ForEach(TMDBMovieDetailPreviewCatalog.allCases) {p in
                        NavigationLink(p.rawValue) {
                            p.view
                        }
                    }
                    
                }
            }
            
            
        }
        
    }
}
