import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
public struct PhotoSlidesPage: View {
    let imagePaths: [String]
    @State private var selectedIndex: Int

    public init(imagePaths: [String], initialIndex: Int = 0) {
        self.imagePaths = imagePaths
        _selectedIndex = State(initialValue: min(max(initialIndex, 0), max(imagePaths.count - 1, 0)))
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                TabView(selection: $selectedIndex) {
                    ForEach(Array(imagePaths.enumerated()), id: \.offset) { index, path in
                        RemoteTMDBImage(
                            posterPath: path,
                            posterSize: PosterSize(width: geometry.size.width, height: geometry.size.height),
                            imageSize: .original,
                            contentMode: .fit
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: imagePaths.count > 1 ? .automatic : .never))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    NavigationStack {
        PhotoSlidesPage(
            imagePaths: [
                "/AvIfrjJL9WRk3TziSvOZCTUHKEn.jpg",
                "/1ffZAucqfvQu36x1C49XfOdjuOG.jpg",
            ],
            initialIndex: 0
        )
    }
}
#endif
