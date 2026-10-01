#if canImport(SwiftfinLib)
import SwiftfinLib
#endif
import SwiftUI

/// Full-screen playback of a Jellyfin library movie.
///
/// Plays the exact item the library search matched. Only a match built outside this module (a
/// preview or a test double) carries no item, and falls back to searching by its title.
@available(iOS 16.0, *)
public struct JellyfinMoviePlayerView: View {
    @Environment(\.dismiss) private var dismiss
    private let match: JellyfinMovieMatch

    public init(match: JellyfinMovieMatch) {
        self.match = match
        SwiftfinRuntime.configureIfNeeded()
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            #if canImport(SwiftfinLib)
            match.item.map(SwiftfinLibrary.moviePlayer(for:)) ?? SwiftfinLibrary.moviePlayer(matching: .keyword(match.title))
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
        .onAppear { SwiftfinWindowAppearanceGuard.swiftfinWillAppear() }
        .onDisappear { SwiftfinWindowAppearanceGuard.swiftfinDidDisappear() }
    }
}

#if DEBUG
/// A match built here carries no library item, so the player searches by title — and, with no
/// Jellyfin account signed in (as in the preview canvas), shows why it cannot play.
@available(iOS 16.0, *)
#Preview {
    JellyfinMoviePlayerView(match: JellyfinMovieMatch(
        id: "preview",
        title: "Dune",
        runtimeSeconds: 9315,
        playedFraction: 0,
        resumeSeconds: 0,
        isPlayed: false
    ))
}
#endif
