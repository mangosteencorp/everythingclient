import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct SeasonCardView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let season: TVShowDetailModel.Season
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: seasonPosterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(2/3, contentMode: .fit)
                    .overlay {
                        Image(systemName: "tv")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 100)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(season.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.labelColor)
                    .lineLimit(2)
                
                Text("\(season.episodeCount) episodes")
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
                
                if let airDate = season.airDate {
                    Text(airDate)
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
                }
            }
        }
        .frame(width: 120)
    }
    
    private var seasonPosterURL: URL? {
        guard let posterPath = season.posterPath else { return nil }
        return TMDBImageSize.small.buildImageUrl(path: posterPath)
    }
}
