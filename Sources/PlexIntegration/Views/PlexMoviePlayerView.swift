import AVKit
import SwiftUI

/// Full-screen playback of a Plex library movie, from the server that matched it.
public struct PlexMoviePlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: PlexMoviePlayerModel

    public init(match: PlexMovieMatch) {
        _model = State(initialValue: PlexMoviePlayerModel(match: match))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                // Sent before the dismissal so the page's progress refresh finds the saved resume point.
                model.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(16)
            }
            .accessibilityLabel(L10n.plexPlayerClose)
            .accessibilityIdentifier("plex.player.close.button")

            VideoPlayer(player: model.player)
                .overlay {
                    if let error = model.error {
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding()
                            .accessibilityIdentifier("plex.player.error")
                    } else if model.player == nil {
                        ProgressView()
                    }
                }
        }
        .background(Color.black.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .task { await model.start() }
        .onDisappear { model.stop() }
    }
}

#if DEBUG
/// A match built here has no server, so the player shows why it cannot play instead of reaching the network.
#Preview {
    PlexMoviePlayerView(match: PlexMovieMatch(
        id: "preview",
        title: "Dune",
        runtimeSeconds: 9315,
        playedFraction: 0,
        resumeSeconds: 0,
        isPlayed: false
    ))
}
#endif
