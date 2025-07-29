import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct TVShowGenresSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let genres: [GenreModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Tvshow.Detail.genres)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)
            
            Text(genres.map { $0.name }.joined(separator: ", "))
                .font(.body)
                .foregroundColor(themeManager.currentTheme.labelColor)
        }
    }
}
