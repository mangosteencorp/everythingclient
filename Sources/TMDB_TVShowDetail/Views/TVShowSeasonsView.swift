import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct TVShowSeasonsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let tvShow: TVShowDetailModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Tvshow.Detail.seasons)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.labelColor)
            
            if tvShow.seasons.count > 4 {
                seasonGridView
            } else {
                seasonRowView
            }
        }
    }
    
    private var seasonRowView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(tvShow.seasons, id: \.id) { season in
                    SeasonCardView(season: season)
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    private var seasonGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(tvShow.seasons.prefix(8), id: \.id) { season in
                SeasonCardView(season: season)
            }
        }
    }
}
