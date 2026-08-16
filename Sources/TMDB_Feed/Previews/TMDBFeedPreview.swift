import SwiftUI
import TMDB_Shared_Backend

#if DEBUG
@available(iOS 16, *)
public struct TMDBFeedDemoView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            MovieFeedListPage(
                // Preview data should always come from the current API response;
                // a cached empty response otherwise masks feed-loading fixes.
                apiService: TMDBAPIService(apiKey: debugTMDBAPIKey, urlCacheOptions: .disabled),
                detailRouteBuilder: { _ in 1 },
                tvShowDetailRouteBuilder: { _ in 1 }
            )
        }
    }
}

@available(iOS 16, *)
#Preview {
    TMDBFeedDemoView()
}

#endif
