import SwiftUI
import Combine

struct RemoteTMDBImage: View {
    let posterPath: String?
    let posterSize: PosterSize
    let image: ImageSize
    var body: some View {
        if let posterPath = posterPath, let url = image.path(poster: posterPath) {
            if #available(iOS 15.0, *) {
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
    @ObservedObject var imageLoader:ImageLoader
    @State var image:UIImage = UIImage()
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

public enum ImageSize: String {
    case small = "https://image.tmdb.org/t/p/w154/"
    case medium = "https://image.tmdb.org/t/p/w500/"
    case cast = "https://image.tmdb.org/t/p/w185/"
    case original = "https://image.tmdb.org/t/p/original/"
    
    func path(poster: String) -> URL? {
        return URL(string: rawValue)?.appendingPathComponent(poster)
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
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, self != nil else { return }
            DispatchQueue.main.async {
                self?.data = data
            }
        }
        task.resume()
    }
}
