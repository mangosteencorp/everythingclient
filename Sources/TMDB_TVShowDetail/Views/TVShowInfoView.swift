import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct TVShowInfoView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let tvShow: TVShowDetailModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            PosterImageView(posterPath: tvShow.posterPath)
            
            VStack(alignment: .leading, spacing: 16) {
                TVShowOverviewSection(overview: tvShow.overview)
                TVShowGenresSection(genres: tvShow.genres)
                TVShowCreatorsSection(creators: tvShow.createdBy)
                TVShowDetailsSection(tvShow: tvShow)
            }
        }
    }
}
