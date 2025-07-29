import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct TVShowDetailsSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let tvShow: TVShowDetailModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Tvshow.Detail.details)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)
            
            VStack(alignment: .leading, spacing: 4) {
                DetailRow(
                    title: L10n.Tvshow.Detail.numberOfSeasons(tvShow.numberOfSeasons)
                )
                DetailRow(
                    title: L10n.Tvshow.Detail.numberOfEpisodes(tvShow.numberOfEpisodes)
                )
                DetailRow(
                    title: L10n.Tvshow.Detail.firstAirDate(tvShow.firstAirDate)
                )
                DetailRow(
                    title: L10n.Tvshow.Detail.lastAirDate(tvShow.lastAirDate)
                )
                DetailRow(
                    title: L10n.Tvshow.Detail.status(tvShow.status)
                )
                DetailRow(
                    title: L10n.Tvshow.Detail.averageVote(Float(tvShow.voteAverage), tvShow.voteCount)
                )
            }
        }
    }
}
