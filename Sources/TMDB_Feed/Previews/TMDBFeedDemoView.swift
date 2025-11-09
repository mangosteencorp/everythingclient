import SwiftUI
import TMDB_Shared_Backend

#if DEBUG
@available(iOS 16, *)
public struct TMDBFeedDemoView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            MovieFeedListPage(
                apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
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
