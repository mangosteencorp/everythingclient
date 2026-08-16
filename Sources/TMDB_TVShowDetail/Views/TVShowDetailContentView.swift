import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct TVShowDetailContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let apiService: TMDBAPIService
    let tvShow: TVShowDetailModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TVShowHeaderView(tvShow: tvShow)
                TVShowInfoView(tvShow: tvShow)

                TVShowWatchProvidersSection(tvShowId: tvShow.id, apiService: apiService)

                TVShowSeasonsView(tvShow: tvShow)
                if #available(iOS 17, *) {
                    SimilarTVSection(
                        viewModel: SimilarTVViewModel(
                            apiService: apiService,
                            tvShowId: tvShow.id
                        )
                    )
                }
            }
            .padding()
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
}
