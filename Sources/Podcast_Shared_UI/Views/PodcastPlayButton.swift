import Podcast_Player
import RSS_Shared_Backend
import SwiftUI

/// Play, pause, or a spinner while loading, for one episode. Borderless, so it works beside other buttons in a
/// `List` row.
public struct PodcastPlayButton: View {
    let episode: PodcastEpisode
    let player: PodcastPlayer

    /// A button that plays and pauses `episode` on `player`.
    public init(episode: PodcastEpisode, player: PodcastPlayer) {
        self.episode = episode
        self.player = player
    }

    public var body: some View {
        let mode = PodcastPlayButtonMode(isCurrent: player.isCurrent(episode), state: player.state)
        Button {
            player.togglePlayPause(episode)
        } label: {
            Group {
                if let systemImage = mode.systemImage {
                    Image(systemName: systemImage)
                        .font(.largeTitle)
                } else {
                    ProgressView()
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(mode.accessibilityLabel)
        .accessibilityIdentifier("podcast.player.playPause")
    }
}

/// What the play button shows for an episode, given the player's state.
enum PodcastPlayButtonMode: Equatable {
    case play
    case pause
    case loading

    /// Anything but the current, playing or loading episode offers to play.
    init(isCurrent: Bool, state: PodcastPlaybackState) {
        switch (isCurrent, state) {
        case (true, .loading): self = .loading
        case (true, .playing): self = .pause
        default: self = .play
        }
    }

    /// The SF Symbol, or nil for a spinner.
    var systemImage: String? {
        switch self {
        case .play: "play.circle.fill"
        case .pause: "pause.circle.fill"
        case .loading: nil
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .play: L10n.play
        case .pause: L10n.pause
        case .loading: L10n.loading
        }
    }
}

#if DEBUG
#Preview {
    PodcastUIPreviewCatalog.playButtons.view
}
#endif
