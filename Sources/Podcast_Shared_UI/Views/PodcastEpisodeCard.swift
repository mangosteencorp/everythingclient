import Podcast_Player
import RSS_Shared_Backend
import SwiftUI

/// One episode with its play button, plus progress and skip controls while it is the player's current episode.
/// Made to sit in a `List` row: every button inside is borderless, so each one hit-tests on its own instead of
/// the whole row triggering the first (see `MovieOSTSection`).
public struct PodcastEpisodeCard: View {
    let episode: PodcastEpisode
    let player: PodcastPlayer

    /// A card for `episode`, played through `player`.
    public init(episode: PodcastEpisode, player: PodcastPlayer) {
        self.episode = episode
        self.player = player
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                PodcastEpisodeRow(episode: episode)
                PodcastPlayButton(episode: episode, player: player)
            }
            if player.isCurrent(episode) {
                if case .failed = player.state {
                    Text(L10n.playbackFailed)
                        .font(.footnote)
                        .foregroundStyle(.red)
                } else {
                    PodcastPlayerControls(player: player)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("podcast.episode.card")
    }
}

#if DEBUG
#Preview("Idle") {
    PodcastUIPreviewCatalog.cardIdle.view
}

#Preview("Loading") {
    PodcastUIPreviewCatalog.cardLoading.view
}

#Preview("Playing") {
    PodcastUIPreviewCatalog.cardPlaying.view
}

#Preview("Paused") {
    PodcastUIPreviewCatalog.cardPaused.view
}

#Preview("Failed") {
    PodcastUIPreviewCatalog.cardFailed.view
}

#Preview("List") {
    PodcastUIPreviewCatalog.episodeList.view
}
#endif
