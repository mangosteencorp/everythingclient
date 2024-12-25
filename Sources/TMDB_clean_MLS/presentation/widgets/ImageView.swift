#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif
import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: PlatformImage?
    private var cancellable: AnyCancellable?
    
    func load(fromURL url: URL) {
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { data, _ -> PlatformImage? in
                #if os(iOS)
                return UIImage(data: data)
                #elseif os(macOS)
                return NSImage(data: data)
                #endif
            }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: self)
    }
}

@available(iOS 14.0, macOS 11.0, *)
struct CustomImageView: View {
    @StateObject private var loader = ImageLoader()
    let imageURL: URL

    var body: some View {
        Group {
            if let image = loader.image {
                #if os(iOS)
                AnyView(Image(uiImage: image).resizable()
                    .aspectRatio(contentMode: .fit))
                #elseif os(macOS)
                AnyView(Image(nsImage: image).resizable()
                    .aspectRatio(contentMode: .fit))
                #endif
                    
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loader.load(fromURL: imageURL)
        }
        .frame(width: 100, height: 100)
    }
}
