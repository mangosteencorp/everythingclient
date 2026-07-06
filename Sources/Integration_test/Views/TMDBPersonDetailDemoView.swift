import SwiftUI
import TMDB_Person
import TMDB_Shared_Backend

#if DEBUG
@available(iOS 16.0, *)
struct TMDBPersonDetailDemoView: View {
    var body: some View {
        NavigationStack {
            PersonDetailPage(
                personId: 287,
                apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
                movieRouteBuilder: { $0 }
            )
        }
        .accessibilityIdentifier("personDetail.demo.page")
    }
}
#endif
