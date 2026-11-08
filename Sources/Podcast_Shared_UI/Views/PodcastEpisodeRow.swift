import RSS_Shared_Backend
import SwiftUI

/// An episode's artwork, title, show, date and length, and a two-line summary. Content only, no actions.
public struct PodcastEpisodeRow: View {
    let episode: PodcastEpisode

    /// Shows `episode`.
    public init(episode: PodcastEpisode) {
        self.episode = episode
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: episode.artworkURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.2)
                    .overlay {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(episode.podcastTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let details = PodcastFormatting.details(of: episode) {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                if let summary = episode.summary {
                    Text(summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("podcast.episode.row")
    }
}

#if DEBUG
#Preview {
    PodcastUIPreviewCatalog.episodeRow.view
}
#endif
