import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15, *)
struct PosterImageView: View {
    let posterPath: String?
    
    var body: some View {
        AsyncImage(url: posterURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            ProgressView()
                .frame(width: 150, height: 225)
        }
        .frame(width: 150)
        .cornerRadius(12)
    }
    
    private var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return TMDBImageSize.medium.buildImageUrl(path: posterPath)
    }
}
