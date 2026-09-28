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
                ForEach(rowTitles, id: \.self) { DetailRow(title: $0) }
            }
        }
    }

    var rowTitles: [String] {
        [
            L10n.Tvshow.Detail.numberOfSeasons(tvShow.numberOfSeasons),
            L10n.Tvshow.Detail.numberOfEpisodes(tvShow.numberOfEpisodes),
            L10n.Tvshow.Detail.firstAirDate(tvShow.firstAirDate),
            L10n.Tvshow.Detail.lastAirDate(tvShow.lastAirDate ?? L10n.Tvshow.Detail.tba),
            L10n.Tvshow.Detail.status(tvShow.status),
            L10n.Tvshow.Detail.averageVote(Float(tvShow.voteAverage), tvShow.voteCount),
        ]
    }
}

#if DEBUG
@available(iOS 15, *)
#Preview {
    TVShowDetailsSection(tvShow: .example)
        .padding()
        .environmentObject(ThemeManager.shared)
}
#endif
