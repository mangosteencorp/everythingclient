#if canImport(SwiftfinLib)
import SwiftfinLib
#endif
import SwiftUI

/// Full-screen playback of a Jellyfin library movie, found by the library title.
///
/// It looks the movie up again rather than being handed the item found earlier: `BaseItemDto` would
/// otherwise have to cross this module's public API and drag JellyfinAPI into every caller.
@available(iOS 16.0, *)
public struct JellyfinMoviePlayerView: View {
    @Environment(\.dismiss) private var dismiss
    private let movieTitle: String

    public init(movieTitle: String) {
        self.movieTitle = movieTitle
        SwiftfinRuntime.configureIfNeeded()
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            #if canImport(SwiftfinLib)
            SwiftfinLibrary.moviePlayer(matching: .keyword(movieTitle))
            #else
            Text("Jellyfin playback is unavailable in this build.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            #endif

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(16)
            }
            .accessibilityLabel("Close player")
            .accessibilityIdentifier("jellyfin.player.close.button")
        }
    }
}
