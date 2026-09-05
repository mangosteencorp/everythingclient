import Kingfisher
import OSLog
import SwiftUI
import TMDB_Shared_Backend
import UIKit

public enum TMDBImageLoader: String, CaseIterable {
    case uiImage
    /// Native HTTP caching on OS 27+; falls back to uiImage on older systems.
    case asyncImage
    case kingfisher

    var resolved: Self {
        if self == .asyncImage {
            #if compiler(>=6.4)
            if #available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *) {
                return .asyncImage
            }
            #endif
            return .uiImage
        }
        return self
    }
}

public struct RemoteTMDBImage: View {
    let posterPath: String?
    let imageSize: TMDBImageSize
    let contentMode: SwiftUI.ContentMode
    let loader: TMDBImageLoader

    private static let logger = Logger(subsystem: "TMDB_Shared_UI", category: "RemoteTMDBImage")

    public init(
        posterPath: String?,
        imageSize: TMDBImageSize,
        contentMode: SwiftUI.ContentMode = .fit,
        loader: TMDBImageLoader = .uiImage
    ) {
        self.posterPath = posterPath
        self.imageSize = imageSize
        self.contentMode = contentMode
        self.loader = loader
    }

    public var body: some View {
        if let posterPath, let url = imageSize.buildImageUrl(path: posterPath) {
            remoteImage(url: url)
                .id("\(url.absoluteString)|\(loader.resolved.rawValue)")
        } else {
            placeholder(url: nil, reason: "Missing, empty, or invalid image path")
        }
    }

    @ViewBuilder
    private func remoteImage(url: URL) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *), loader.resolved == .asyncImage {
            AsyncImage(request: URLRequest(url: url)) { phase in
                phaseContent(phase, url: url)
            }
            .asyncImageURLSession(TMDBImageDownload.session)
        } else {
            cachedImage(url: url)
        }
        #else
        cachedImage(url: url)
        #endif
    }

    private func cachedImage(url: URL) -> some View {
        CachedTMDBImage(url: url, loader: loader.resolved) { phase in
            phaseContent(phase, url: url)
        }
    }

    @ViewBuilder
    private func phaseContent(_ phase: AsyncImagePhase, url: URL) -> some View {
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
        case let .failure(error):
            placeholder(url: url, reason: String(reflecting: error))
        @unknown default:
            placeholder(url: url, reason: "Unknown image loading phase")
        }
    }

    private func placeholder(url: URL?, reason: String) -> some View {
        PlaceholderImage()
            .onAppear {
                #if DEBUG
                Self.logger.error("""
                    PlaceholderImage loader=\(loader.rawValue, privacy: .public) \
                    resolvedLoader=\(loader.resolved.rawValue, privacy: .public) \
                    path=\(posterPath ?? "missing", privacy: .public) \
                    size=\(String(describing: imageSize), privacy: .public) \
                    url=\(url?.absoluteString ?? "nil", privacy: .public) \
                    error=\(reason, privacy: .public)
                    """)
                #endif
            }
    }
}

private struct CachedTMDBImage<Content: View>: View {
    let url: URL
    let loader: TMDBImageLoader
    @ViewBuilder let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase = .empty

    var body: some View {
        content(phase)
            .task {
                phase = .empty
                do {
                    let image: UIImage
                    if loader == .kingfisher {
                        // Kingfisher's default cache stores images in memory and on disk.
                        image = try await KingfisherManager.shared.retrieveImage(with: url).image
                    } else {
                        image = try await TMDBImageDownload.loadUIImage(from: url)
                    }
                    try Task.checkCancellation()
                    phase = .success(Image(uiImage: image))
                } catch {
                    // A disappearing/reused row is not a failed image.
                    guard !Task.isCancelled else { return }
                    phase = .failure(error)
                }
            }
    }
}

enum TMDBImageDownload {
    // Both native loaders share the same memory/disk HTTP cache and respect server expiry.
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 128 * 1024 * 1024,
            diskPath: "tmdb-images"
        )
        return URLSession(configuration: configuration)
    }()

    static func loadUIImage(from url: URL, session: URLSession = session) async throws -> UIImage {
        let (data, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse, userInfo: [
                NSURLErrorFailingURLErrorKey: url,
                NSLocalizedDescriptionKey: "Image HTTP status \((response as? HTTPURLResponse)?.statusCode ?? -1)",
            ])
        }
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData, userInfo: [NSURLErrorFailingURLErrorKey: url])
        }
        return image
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
