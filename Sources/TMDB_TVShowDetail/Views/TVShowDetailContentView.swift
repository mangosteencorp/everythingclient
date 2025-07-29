import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct TVShowDetailContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let tvShow: TVShowDetailModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TVShowHeaderView(tvShow: tvShow)
                TVShowInfoView(tvShow: tvShow)
                TVShowSeasonsView(tvShow: tvShow)
            }
            .padding()
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
}
