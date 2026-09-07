import MusicKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 16.0, *)
public struct MovieOSTSection: View {
    @ObservedObject var ostViewModel: MovieOSTViewModel

    public init(ostViewModel: MovieOSTViewModel) {
        self.ostViewModel = ostViewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Soundtrack")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityIdentifier("movieDetail.ost.section")

            switch ostViewModel.state {
            case .notDetermined:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connect Apple Music to find this movie's soundtrack.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Connect Apple Music") {
                        Task { await ostViewModel.requestAuthorization() }
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("movieDetail.ost.requestPermission.button")
                }
                .padding(.horizontal)

            case .denied:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apple Music access is required to search for soundtracks.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        Link("Open Settings", destination: settingsURL)
                    }
                }
                .padding(.horizontal)

            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Searching for soundtrack...")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

            case .success(let albums):
                VStack(spacing: 12) {
                    ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                        MovieOSTAlbumRow(album: album, index: index)
                    }
                }
                .padding(.horizontal)

            case .empty:
                Text("No soundtrack albums found on Apple Music.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

            case .error(let message):
                Text("Could not load soundtrack: \(message)")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 16.0, *)
private struct MovieOSTAlbumRow: View {
    let album: MovieOSTAlbumDisplayModel
    let index: Int

    var body: some View {
        Group {
            if let url = album.url {
                Link(destination: url) {
                    albumContent
                }
                // The whole section is a single `List` row, so every album `Link` lives in that
                // one row. With the automatic button style the row becomes one tap target and
                // activates the first link no matter which album is tapped; `.borderless` makes
                // each link hit-test on its own.
                .buttonStyle(.borderless)
            } else {
                albumContent
            }
        }
        .accessibilityIdentifier("movieDetail.ost.album.\(index)")
    }

    private var albumContent: some View {
        HStack(spacing: 12) {
            if let artwork = album.artwork {
                ArtworkImage(artwork, width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(album.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let trackCount = album.trackCount {
                    Text("\(trackCount) tracks")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)

            if album.url != nil {
                Image(systemName: "arrow.up.forward.app")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // Without an explicit shape only the drawn subviews are tappable, leaving the padding
        // and the trailing spacer inert.
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    List {
        MovieOSTSection(ostViewModel: {
            let viewModel = MovieOSTViewModel()
            viewModel.state = .success([
                MovieOSTAlbumDisplayModel(
                    id: "1",
                    title: "Superman (Original Motion Picture Soundtrack)",
                    artistName: "Various Artists",
                    trackCount: 24,
                    artwork: nil,
                    url: URL(string: "https://music.apple.com")
                ),
            ])
            return viewModel
        }())
    }
}
#endif
