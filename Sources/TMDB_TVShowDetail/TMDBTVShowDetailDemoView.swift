import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

#if DEBUG
@available(iOS 15, *)
public struct TMDBTVShowDetailDemoView: View {
    public init() {}

    public var body: some View {
        TVShowDetailView(
            tvShowId: 1399, // Game of Thrones ID
            apiService: TMDBAPIService(apiKey: debugTMDBAPIKey)
        )
        .environmentObject(ThemeManager.shared)
    }
}

#if DEBUG
@available(iOS 15, *)
#Preview {
    TMDBTVShowDetailDemoView()
}
#endif
#endif
