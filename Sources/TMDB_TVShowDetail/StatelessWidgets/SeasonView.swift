import CoreFeatures
import SwiftUI

@available(iOS 15, *)
struct SeasonView: View {
    let season: Season
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: season.posterURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 150, height: 225)

            Text(season.name)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.labelColor)

            Text("\(season.episodeCount) episodes")
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7)) // Secondary text effect

            Text("Air date: \(season.airDate)")
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7)) // Secondary text effect
        }
        .frame(width: 150)
        .padding(.bottom, 10)
        .background(themeManager.currentTheme.backgroundColor) // Use theme background
        .cornerRadius(10)
    }
}
