import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
struct PersonProfileImageView: View {
    let profilePath: String?

    var body: some View {
        AsyncImage(url: profilePath.flatMap { TMDBImageSize.profileLarge.buildImageUrl(path: $0) }) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .empty:
                ProgressView()
            case .failure:
                Image(systemName: "person.crop.square")
                    .font(.system(size: 38))
                    .foregroundStyle(.secondary)
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 118, height: 168)
        .background(Color.platformTertiaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}
