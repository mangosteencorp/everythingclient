import PlexIntegration
import SwiftUI

/// `MovieJellyfinSection` for Plex, with Play only: there is no Plex app page to open the movie in.
struct MoviePlexSection: View {
    @ObservedObject var plexViewModel: MoviePlexViewModel
    let movieTitle: String
    let movieYear: Int?
    @State private var isPlaying = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.plexSectionTitle)
                .font(.headline)
                .accessibilityIdentifier("movieDetail.plex.section")

            switch plexViewModel.state {
            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                    Text(L10n.plexCheckingLibrary)
                        .foregroundStyle(.secondary)
                }

            case let .found(match):
                MoviePlexMatchView(match: match) { isPlaying = true }
                    .fullScreenCover(isPresented: $isPlaying, onDismiss: {
                        Task {
                            await plexViewModel.reloadIfCurrent(title: movieTitle, year: movieYear)
                        }
                    }, content: {
                        PlexMoviePlayerView(match: match)
                    })

            case .error(let message):
                SectionRetryView(message: message) {
                    await plexViewModel.reload(title: movieTitle, year: movieYear)
                }

            case .unavailable, .notInLibrary:
                EmptyView()
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MoviePlexMatchView: View {
    let match: PlexMovieMatch
    let play: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(match.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Spacer(minLength: 0)
                if match.isPlayed {
                    Label(L10n.plexWatched, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .labelStyle(.titleAndIcon)
                }
            }

            if isInProgress {
                ProgressView(value: match.playedFraction)
                    .accessibilityIdentifier("movieDetail.plex.progress")
                Text(L10n.plexWatchedProgressFormat(Int((match.playedFraction * 100).rounded()), remainingText))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: play) {
                Label(L10n.plexPlay, systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(isInProgress ? L10n.plexResumeHint(formatted(match.resumeSeconds)) : "")
            .accessibilityIdentifier("movieDetail.plex.play.button")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Started but not finished: a played movie keeps its position, so the resume offer has to be
    /// suppressed once the server marks it watched.
    private var isInProgress: Bool {
        !match.isPlayed && match.resumeSeconds > 0
    }

    private var remainingText: String {
        guard let runtimeSeconds = match.runtimeSeconds else { return L10n.plexElapsedFormat(formatted(match.resumeSeconds)) }
        return L10n.plexRemainingFormat(formatted(runtimeSeconds - match.resumeSeconds))
    }

    private func formatted(_ seconds: Double) -> String {
        Duration.seconds(max(seconds, 0)).formatted(.time(pattern: .hourMinuteSecond))
    }
}

#if DEBUG
#Preview {
    TMDBMovieDetailPreviewCatalog.plexSection.view
}

#Preview("Movie actions") {
    VStack {
        MoviePlexMatchView(
            match: PlexMovieMatch(id: "1", title: "Dune", runtimeSeconds: 9315, playedFraction: 0.35, resumeSeconds: 3260, isPlayed: false),
            play: {}
        )
        MoviePlexMatchView(
            match: PlexMovieMatch(id: "2", title: "Dune: Part Two", runtimeSeconds: 9960, playedFraction: 1, resumeSeconds: 0, isPlayed: true),
            play: {}
        )
    }
    .padding()
}
#endif
