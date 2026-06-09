import Combine
import SwiftUI

public struct RemoteTMDBImage: View {
    let posterPath: String?
    let posterSize: PosterSize
    let imageSize: TMDBImageSize
    let contentMode: ContentMode
    public init(posterPath: String?, posterSize: PosterSize, imageSize: TMDBImageSize, contentMode: ContentMode = .fit) {
        self.posterPath = posterPath
        self.posterSize = posterSize
        self.imageSize = imageSize
        self.contentMode = contentMode
    }

    public var body: some View {
        if let posterPath = posterPath, let url = imageSize.buildImageUrl(path: posterPath) {
            if #available(iOS 15.0, *) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: posterSize.width, height: posterSize.height)
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: self.contentMode)
                            .frame(width: posterSize.width, height: posterSize.height)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    case .failure:
                        PlaceholderImage(posterSize: posterSize)
                    @unknown default:
                        EmptyView()
                            .frame(width: posterSize.width, height: posterSize.height)
                    }
                }
            } else {
                ImageView(url: url, posterSize: posterSize)
            }
        } else {
            PlaceholderImage(posterSize: posterSize)
        }
    }
}

struct ImageView: View {
    @ObservedObject var imageLoader: ImageLoader
    @State var image: UIImage = .init()
    let posterSize: PosterSize

    init(url: URL, posterSize: PosterSize) {
        imageLoader = ImageLoader(url: url)
        self.posterSize = posterSize
    }

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: posterSize.width, height: posterSize.height)
            .onReceive(imageLoader.didChange) { data in
                self.image = UIImage(data: data) ?? UIImage()
            }
    }
}

struct PlaceholderImage: View {
    var posterSize: PosterSize

    var body: some View {
        Image(systemName: "photo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: posterSize.width, height: posterSize.height)
            .foregroundColor(.gray)
    }
}

class ImageLoader: ObservableObject {
    var didChange = PassthroughSubject<Data, Never>()
    var data = Data() {
        didSet {
            didChange.send(data)
        }
    }

    init(url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, self != nil else { return }
            DispatchQueue.main.async {
                self?.data = data
            }
        }
        task.resume()
    }
}
