import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
public struct PhotoCarouselView<Route: Hashable>: View {
    let title: String
    let imagePaths: [String]
    let photoSlidesRouteBuilder: ([String], Int) -> Route

    public init(
        title: String,
        imagePaths: [String],
        photoSlidesRouteBuilder: @escaping ([String], Int) -> Route
    ) {
        self.title = title
        self.imagePaths = imagePaths
        self.photoSlidesRouteBuilder = photoSlidesRouteBuilder
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .titleStyle()
                .padding(.leading)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(imagePaths.enumerated()), id: \.offset) { index, path in
                        NavigationLink(value: photoSlidesRouteBuilder(imagePaths, index)) {
                            RemoteTMDBImage(
                                posterPath: path,
                                posterSize: PosterSize(width: 180, height: 100),
                                imageSize: .backdropSmall,
                                contentMode: .fill
                            )
                            .frame(width: 180, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical)
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    NavigationStack {
        List {
            PhotoCarouselView(
                title: "Photos",
                imagePaths: [
                    "/AvIfrjJL9WRk3TziSvOZCTUHKEn.jpg",
                    "/1ffZAucqfvQu36x1C49XfOdjuOG.jpg",
                ],
                photoSlidesRouteBuilder: { _, index in index }
            )
        }
    }
}
#endif
