import SwiftUI
@available(iOS 15, macOS 12, *)
struct MoviePosterImage: View {
    var posterPath: String?
    var posterSize: PosterSize

    var body: some View {
        if let posterPath = posterPath, let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: posterSize.width, height: posterSize.height)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: posterSize.width, height: posterSize.height)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: posterSize.width, height: posterSize.height)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                        .frame(width: posterSize.width, height: posterSize.height)
                }
            }
        } else {
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: posterSize.width, height: posterSize.height)
                .foregroundColor(.gray)
        }
    }

}
