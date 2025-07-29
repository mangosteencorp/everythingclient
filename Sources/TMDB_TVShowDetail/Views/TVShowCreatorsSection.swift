import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct TVShowCreatorsSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let creators: [TVShowDetailModel.Creator]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Tvshow.Detail.createdBy)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(creators, id: \.id) { creator in
                        CreatorView(creator: creator)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}
