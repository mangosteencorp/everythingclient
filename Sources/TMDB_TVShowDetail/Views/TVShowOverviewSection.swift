import CoreFeatures
import SwiftUI

@available(iOS 15, *)
struct TVShowOverviewSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let overview: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Tvshow.Detail.overview)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)
            
            Text(overview)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.labelColor)
        }
    }
}
