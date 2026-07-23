import SwiftUI
import TMDB_MovieDetail
import TMDB_Shared_Backend

#if DEBUG
public struct TMDBMovieDetailDemoView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            MovieDetailPage(
                movieId: 1061474,
                apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
                discoverMovieByKeywordRouteBuilder: { $0 },
                personRouteBuilder: { $0 },
                photoSlidesRouteBuilder: { _, index in index }
            )
            .navigationTitle("Movie Detail")
        }
        .accessibilityIdentifier("movieDetail.demo.page")
    }
}

#if DEBUG
#Preview {
    TMDBMovieDetailDemoView()
}
#endif
#endif
