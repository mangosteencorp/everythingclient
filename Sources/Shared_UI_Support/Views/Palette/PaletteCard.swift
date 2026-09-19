import Kingfisher
import SwiftUI

/// A card that tints itself with its own artwork: the background is the image's average
/// colour, and everything inside it is drawn in the colour that stays readable on top.
///
/// Domain-free — it takes a URL and a caption. `TMDB_Feed` uses it for posters, but anything
/// with a picture and a title fits.
public struct PaletteCard<Content: View>: View {
    private let imageURL: URL?
    private let aspectRatio: CGFloat
    private let cornerRadius: CGFloat
    private let content: () -> Content

    @StateObject private var loader = ImagePaletteLoader()

    public init(
        imageURL: URL?,
        aspectRatio: CGFloat = 2.0 / 3.0,
        cornerRadius: CGFloat = 14,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.imageURL = imageURL
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            poster
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
        }
        .background(loader.palette.background)
        .foregroundStyle(loader.palette.foreground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .animation(.easeOut(duration: 0.25), value: loader.palette)
        .task(id: imageURL) { await loader.load(imageURL) }
    }

    @ViewBuilder
    private var poster: some View {
        if let imageURL {
            KFImage(imageURL)
                .resizable()
                .fade(duration: 0.25)
                .aspectRatio(aspectRatio, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
        } else {
            Rectangle()
                .fill(.quaternary)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }
}
