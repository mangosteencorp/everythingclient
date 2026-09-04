import SwiftUI
import TMDB_Shared_Backend

public struct RemoteTMDBImage: View {
    let posterPath: String?
    let imageSize: TMDBImageSize
    let contentMode: ContentMode

    public init(
        posterPath: String?,
        imageSize: TMDBImageSize,
        contentMode: ContentMode = .fit
    ) {
        self.posterPath = posterPath
        self.imageSize = imageSize
        self.contentMode = contentMode
    }

    public var body: some View {
        if let posterPath, let url = imageSize.buildImageUrl(path: posterPath) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                case .failure:
                    PlaceholderImage()
                @unknown default:
                    Color.clear
                }
            }
        } else {
            PlaceholderImage()
        }
    }
}

struct PlaceholderImage: View {
    var body: some View {
        Image(systemName: "photo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.gray)
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
