import SwiftUI
import third_party

@available(iOS 16.0, *)
public struct MovieJellyfinSection: View {
    @ObservedObject var jellyfinViewModel: MovieJellyfinViewModel
    let movieTitle: String
    let movieId: Int
    @State private var isPlaying = false

    public init(movieTitle: String, movieId: Int, jellyfinViewModel: MovieJellyfinViewModel) {
        self.movieTitle = movieTitle
        self.movieId = movieId
        self.jellyfinViewModel = jellyfinViewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("On Jellyfin")
                .font(.headline)
                .accessibilityIdentifier("movieDetail.jellyfin.section")

            switch jellyfinViewModel.state {
            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Checking your Jellyfin library...")
                        .foregroundStyle(.secondary)
                }

            case let .found(match):
                MovieJellyfinMatchView(match: match) { isPlaying = true }
                    .fullScreenCover(isPresented: $isPlaying) {
                        JellyfinMoviePlayerView(movieTitle: match.title)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(match.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Spacer(minLength: 0)
                if match.isPlayed {
                    Label("Watched", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .labelStyle(.titleAndIcon)
                }
            }

            if isInProgress {
                ProgressView(value: match.playedFraction)
                    .accessibilityIdentifier("movieDetail.jellyfin.progress")
                Text("\(Int((match.playedFraction * 100).rounded()))% watched \u{2022} \(remainingText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: play) {
                Label(isInProgress ? "Resume from \(formatted(match.resumeSeconds))" : "Play",
                      systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("movieDetail.jellyfin.play.button")
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
        guard let runtimeSeconds = match.runtimeSeconds else { return "\(formatted(match.resumeSeconds)) in" }
        return "\(formatted(runtimeSeconds - match.resumeSeconds)) left"
    }

    private func formatted(_ seconds: Double) -> String {
        Duration.seconds(max(seconds, 0)).formatted(.time(pattern: .hourMinuteSecond))
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    List {
        Section {
            MovieJellyfinSection(movieTitle: "Dune", movieId: 438_631, jellyfinViewModel: {
                let viewModel = MovieJellyfinViewModel()
                viewModel.state = .found(
                    JellyfinMovieMatch(
                        id: "abc",
                        title: "Dune (2021)",
                        runtimeSeconds: 9315,
                        playedFraction: 0.35,
                        resumeSeconds: 3260,
                        isPlayed: false
                    )
                )
                return viewModel
            }())
        }
    }
}
#endif
