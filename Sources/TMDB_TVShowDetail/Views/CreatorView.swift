import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct CreatorView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let creator: TVShowDetailModel.Creator
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: profileImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            Text(creator.name)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.labelColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 70)
    }
    
    private var profileImageURL: URL? {
        guard let profilePath = creator.profilePath else { return nil }
        return TMDBImageSize.cast.buildImageUrl(path: profilePath)
    }
}
