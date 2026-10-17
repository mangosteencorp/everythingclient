import SwiftfinLauncher
import SwiftUI

@available(iOS 16.0, *)
public struct MovieJellyfinSection: View {
    @ObservedObject var jellyfinViewModel: MovieJellyfinViewModel
    let movieTitle: String
    let movieId: Int
    @State private var destination: Destination?

    private enum Destination: String, Identifiable {
        case play, details

        var id: String { rawValue }
    }

    public init(movieTitle: String, movieId: Int, jellyfinViewModel: MovieJellyfinViewModel) {
        self.movieTitle = movieTitle
        self.movieId = movieId
        self.jellyfinViewModel = jellyfinViewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.jellyfinSectionTitle)
                .font(.headline)
                .accessibilityIdentifier("movieDetail.jellyfin.section")

            switch jellyfinViewModel.state {
            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                    Text(L10n.jellyfinCheckingLibrary)
                        .foregroundStyle(.secondary)
                }

            case let .found(match):
                MovieJellyfinMatchView(
                    match: match,
                    play: { destination = .play },
                    open: { destination = .details }
                )
                    .fullScreenCover(item: $destination) { destination in
                        switch destination {
                        case .play:
                            JellyfinMoviePlayerView(match: match)
                        case .details:
                            JellyfinMovieDetailView(match: match)
                        }
                    }

            case .error(let message):
                SectionRetryView(message: message) {
                    await jellyfinViewModel.reload(title: movieTitle, tmdbID: movieId)
                }

            case .unavailable, .notInLibrary:
                EmptyView()
            }
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 16.0, *)
private struct MovieJellyfinMatchView: View {
    let match: JellyfinMovieMatch
    let play: () -> Void
    let open: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(match.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Spacer(minLength: 0)
                if match.isPlayed {
                    Label(L10n.jellyfinWatched, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .labelStyle(.titleAndIcon)
                }
            }

            if isInProgress {
                ProgressView(value: match.playedFraction)
                    .accessibilityIdentifier("movieDetail.jellyfin.progress")
                Text(L10n.jellyfinWatchedProgressFormat(Int((match.playedFraction * 100).rounded()), remainingText))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button(action: play) {
                    Label(L10n.jellyfinPlay, systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint(isInProgress ? L10n.jellyfinResumeHint(formatted(match.resumeSeconds)) : "")
                .accessibilityIdentifier("movieDetail.jellyfin.play.button")

                Button(action: open) {
                    Label(L10n.jellyfinOpen, systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!JellyfinMovieDetailView.isAvailable)
                .accessibilityHint(JellyfinMovieDetailView.isAvailable ? L10n.jellyfinOpenHint : L10n.jellyfinOpenUnavailable)
                .accessibilityIdentifier("movieDetail.jellyfin.open.button")
            }

            if !JellyfinMovieDetailView.isAvailable {
                Text(L10n.jellyfinOpenUnavailable)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
        guard let runtimeSeconds = match.runtimeSeconds else { return L10n.jellyfinElapsedFormat(formatted(match.resumeSeconds)) }
        return L10n.jellyfinRemainingFormat(formatted(runtimeSeconds - match.resumeSeconds))
    }

    private func formatted(_ seconds: Double) -> String {
        Duration.seconds(max(seconds, 0)).formatted(.time(pattern: .hourMinuteSecond))
    }
}

#if DEBUG
#Preview {
    TMDBMovieDetailPreviewCatalog.jellyfinSection.view
}

#Preview("Movie actions") {
    MovieJellyfinMatchView(
        match: JellyfinMovieMatch(
            id: "preview",
            title: "Dune",
            runtimeSeconds: 9315,
            playedFraction: 0,
            resumeSeconds: 0,
            isPlayed: false
        ),
        play: {},
        open: {}
    )
    .padding()
}
#endif
