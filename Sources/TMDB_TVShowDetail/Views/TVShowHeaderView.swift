import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct TVShowHeaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let tvShow: TVShowDetailModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tvShow.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.labelColor)
            
            if !tvShow.tagline.isEmpty {
                Text(tvShow.tagline)
                    .font(.title2)
                    .italic()
                    .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
            }
        }
    }
}
