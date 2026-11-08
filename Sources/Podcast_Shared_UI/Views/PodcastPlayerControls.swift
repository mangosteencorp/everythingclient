import Podcast_Player
import SwiftUI

/// Progress, elapsed and remaining time, and skip back 15 s / forward 30 s for the player's current episode.
/// The skip buttons are borderless, so they work inside a `List` row.
public struct PodcastPlayerControls: View {
    static let skipBackSeconds = 15
    static let skipForwardSeconds = 30

    let player: PodcastPlayer

    /// Controls for whatever `player` has loaded.
    public init(player: PodcastPlayer) {
        self.player = player
    }

    public var body: some View {
        VStack(spacing: 6) {
            ProgressView(value: player.progress)
                .accessibilityLabel(L10n.playbackProgress)
                .accessibilityValue(PodcastFormatting.time(player.currentTime))
                .accessibilityIdentifier("podcast.player.progress")
            HStack {
                Text(PodcastFormatting.time(player.currentTime))
                Spacer()
                Button {
                    player.skip(by: -TimeInterval(Self.skipBackSeconds))
                } label: {
                    Image(systemName: "gobackward.15")
                }
                .accessibilityLabel(L10n.skipBackFormat(Self.skipBackSeconds))
                .accessibilityIdentifier("podcast.player.skipBack")
                Button {
                    player.skip(by: TimeInterval(Self.skipForwardSeconds))
                } label: {
                    Image(systemName: "goforward.30")
                }
                .accessibilityLabel(L10n.skipForwardFormat(Self.skipForwardSeconds))
                .accessibilityIdentifier("podcast.player.skipForward")
                Spacer()
                Text(PodcastFormatting.remaining(player.duration - player.currentTime))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .buttonStyle(.borderless)
            .imageScale(.large)
        }
    }
}

#if DEBUG
#Preview {
    PodcastUIPreviewCatalog.playerControls.view
}
#endif
