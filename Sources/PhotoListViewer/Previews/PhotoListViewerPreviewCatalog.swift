#if DEBUG
import SwiftUI

/// Every photo viewer preview as a view of its own, so Xcode's canvas, the integration launcher and
/// the screenshot run all render the same thing. The photos are Paddington in Peru stills, fetched
/// from TMDB's image CDN.
public enum PhotoListViewerPreviewCatalog: String, CaseIterable {
    case slidesPage
    case carousel

    @MainActor @ViewBuilder
    public var view: some View {
        NavigationStack {
            switch self {
            case .slidesPage:
                PhotoSlidesPage(imagePaths: Array(Self.imagePaths.prefix(2)), initialIndex: 0)
            case .carousel:
                List {
                    PhotoCarouselView(title: "Photos", imagePaths: Self.imagePaths, photoSlidesRouteBuilder: { _, index in index })
                }
            }
        }
    }

    private static let imagePaths = [
        "/AvIfrjJL9WRk3TziSvOZCTUHKEn.jpg",
        "/1ffZAucqfvQu36x1C49XfOdjuOG.jpg",
        "/5rhTDKUhPYvpdQIijFIs5VoWsON.jpg",
        "/sSIzzVhhLfgLKVBcAUv0X6cLYz9.jpg",
    ]
}
#endif
