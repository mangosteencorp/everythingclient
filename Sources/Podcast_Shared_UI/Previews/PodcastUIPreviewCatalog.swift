#if DEBUG
import Podcast_Player
import RSS_Shared_Backend
import SwiftUI

/// Every podcast UI preview as a view of its own, so Xcode's canvas, the integration launcher and the screenshot
/// run all render the same thing. Episodes are samples and players are silent: nothing loads a feed or audio.
public enum PodcastUIPreviewCatalog: String, CaseIterable, Identifiable {
    public var id: String {
        rawValue
    }

    case episodeRow
    case playButtons
    case playerControls
    case cardIdle
    case cardLoading
    case cardPlaying
    case cardPaused
    case cardFailed
    case episodeList

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .episodeRow:
            List(PodcastEpisode.previews) { PodcastEpisodeRow(episode: $0) }
        case .playButtons:
            HStack(spacing: 24) {
                PodcastPlayButton(episode: .preview, player: .preview())
                PodcastPlayButton(episode: .preview, player: .preview(.loading))
                PodcastPlayButton(episode: .preview, player: .preview(.playing))
            }
        case .playerControls:
            PodcastPlayerControls(player: .preview(.playing, elapsed: 125))
                .padding()
        case .episodeList:
            List(PodcastEpisode.previews) { PodcastEpisodeCard(episode: $0, player: Self.sharedPlayer) }
        default:
            List {
                Section {
                    PodcastEpisodeCard(episode: .preview, player: cardPlayer)
                }
            }
        }
    }

    @MainActor
    private var cardPlayer: PodcastPlayer {
        switch self {
        case .cardLoading: .preview(.loading)
        case .cardPlaying: .preview(.playing, elapsed: 125)
        case .cardPaused: .preview(.paused, elapsed: 125)
        case .cardFailed: .preview(.failed("The operation couldn’t be completed."))
        default: .preview()
        }
    }

    /// One player for the whole list, so starting an episode shows the others as not playing.
    @MainActor private static let sharedPlayer = PodcastPlayer.preview(.playing, elapsed: 60)
}
#endif
