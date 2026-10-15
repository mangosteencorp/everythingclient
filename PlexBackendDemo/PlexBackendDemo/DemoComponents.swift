import Plex_Shared_Backend
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Artwork

/// Server artwork through `/photo/:/transcode`, sent with header credentials. The API's caching transport keeps
/// the image bytes (never the request headers), so posters still appear offline.
struct PlexArtwork: View {
    let path: String?
    var width: CGFloat = 60
    var height: CGFloat = 90
    @Environment(DemoSession.self) private var session
    @State private var image: Image?

    var body: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            if let image {
                image.resizable().scaledToFill()
            } else {
                Image(systemName: "photo").foregroundStyle(.secondary)
            }
        }
        .frame(width: width, height: height)
        .clipShape(.rect(cornerRadius: 6))
        .accessibilityHidden(true)
        .task(id: path) { image = await load() }
    }

    private func load() async -> Image? {
        guard let path, let api = session.api,
              let data = try? await api.imageData(path: path, width: Int(width * 2), height: Int(height * 2))
        else { return nil }
#if os(macOS)
        return NSImage(data: data).map(Image.init(nsImage:))
#else
        return UIImage(data: data).map(Image.init(uiImage:))
#endif
    }
}

// MARK: - Rows and cards

extension PlexMetadata {
    var typeName: LocalizedStringResource {
        switch type {
        case "movie": "Movie"
        case "show": "TV show"
        case "season": "Season"
        case "episode": "Episode"
        case "collection": "Collection"
        case "playlist": "Playlist"
        case "clip": "Extra"
        default: "Item"
        }
    }

    /// "S1 E2" for episodes.
    var episodeLabel: String? {
        guard type == "episode", let season = parentIndex, let episode = index else { return nil }
        return String(localized: "S\(season) E\(episode)")
    }

    /// "The Show · S1 E2" for episodes, counts for containers, otherwise year and type.
    var detailLine: String {
        if let episodeLabel { return String(localized: "\(grandparentTitle ?? "") · \(episodeLabel)") }
        if type == "season", let count = leafCount { return String(localized: "Episodes: \(count)") }
        if let count = childCount ?? leafCount, ["collection", "playlist"].contains(type) {
            return String(localized: "Items: \(count)")
        }
        guard let year else { return String(localized: typeName) }
        return String(localized: "\(year.formatted(.number.grouping(.never))) · \(typeName)")
    }

    var isPlayable: Bool { ["movie", "episode", "clip"].contains(type) }
    var hasChildren: Bool { ["show", "season", "collection", "playlist"].contains(type) }
}

/// One library item: poster, title, detail line, progress and watched state.
struct MediaRow: View {
    let item: PlexMetadata
    var watchedOverride: Bool?

    var body: some View {
        HStack(spacing: 12) {
            PlexArtwork(path: item.posterPath, width: 44, height: 66)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.headline).lineLimit(2)
                Text(item.detailLine).font(.caption).foregroundStyle(.secondary)
                if let progress = item.progress { ProgressView(value: progress).frame(maxWidth: 160) }
            }
            Spacer(minLength: 0)
            if watchedOverride ?? item.isWatched {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).accessibilityLabel("Watched")
            }
        }
        .contentShape(.rect)
    }
}

/// A poster with a caption, for horizontal shelves.
struct PosterCard: View {
    let item: PlexMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            PlexArtwork(path: item.posterPath, width: 110, height: 165)
                .overlay(alignment: .bottom) {
                    if let progress = item.progress { ProgressView(value: progress).padding(6) }
                }
            Text(item.type == "episode" ? item.grandparentTitle ?? item.title : item.title)
                .font(.caption.bold()).lineLimit(1)
            Text(item.episodeLabel ?? item.detailLine).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(width: 110)
        .contentShape(.rect)
    }
}

/// A titled horizontal shelf. "See all" follows the hub's own list key.
struct HubShelf: View {
    let title: String
    let items: [PlexMetadata]
    var hub: PlexHub?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.title3.bold())
                Spacer()
                if let hub, hub.key != nil { NavigationLink("See all", value: hub) }
            }
            .padding(.horizontal)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink(value: item) { PosterCard(item: item) }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Navigation

/// A person from a cast or crew list.
struct PersonDestination: Hashable {
    let tag: PlexTag
}

extension View {
    /// Shared push destinations so every tab can open items, people, hubs and folders.
    func plexDestinations() -> some View {
        navigationDestination(for: PlexMetadata.self) { ItemDetailView(summary: $0) }
            .navigationDestination(for: PersonDestination.self) { person in
                PagedItemsScreen(title: person.tag.tag) { api, page in
                    try await api.personMedia(personID: person.tag.tagID ?? "", page: page)
                }
            }
            .navigationDestination(for: PlexHub.self) { hub in
                PagedItemsScreen(title: hub.title) { api, page in try await api.container(key: hub.key ?? "", page: page) }
            }
            .navigationDestination(for: PlexDirectory.self) { folder in
                PagedItemsScreen(title: folder.title) { api, page in try await api.container(key: folder.key, page: page) }
            }
            .navigationDestination(for: PlexLibrary.self) { LibrarySectionView(library: $0) }
    }
}

/// Shown when no server is connected.
struct ConnectPrompt: View {
    var body: some View {
        ContentUnavailableView(
            "Connect to a Plex server", systemImage: "network",
            description: Text("Use Account to sign in, or explore the sample library.")
        )
    }
}

#Preview("Media row") {
    MediaRow(item: PlexMetadata(ratingKey: "1", title: "The Sample Movie", type: "movie", year: 2026, duration: 600, viewOffset: 200))
        .padding().environment(DemoSession.preview())
}

#Preview("Poster card") {
    PosterCard(item: PlexMetadata(ratingKey: "1", title: "Pilot", type: "episode", index: 1, parentIndex: 1, grandparentTitle: "Show"))
        .padding().environment(DemoSession.preview())
}

#Preview("Hub shelf") {
    NavigationStack {
        HubShelf(title: "Recently added", items: [
            PlexMetadata(ratingKey: "1", title: "The Sample Movie", type: "movie", year: 2026),
            PlexMetadata(ratingKey: "2", title: "Second Feature", type: "movie", year: 2025, viewCount: 1),
        ])
    }
    .environment(DemoSession.preview())
}

#Preview("Artwork") { PlexArtwork(path: nil).environment(DemoSession.preview()) }
#Preview("Connect prompt") { ConnectPrompt() }
