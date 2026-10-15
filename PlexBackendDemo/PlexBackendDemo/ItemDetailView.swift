import Plex_Shared_Backend
import SwiftUI

/// What the player should open: server items (a single item or a play queue) or a downloaded file.
struct PlaybackRequest: Identifiable {
    let id = UUID()
    var items: [PlexMetadata]
    var mediaIndex = 0
    var localFile: URL?
    var serverID: String?
}

/// Everything Plezy offers on an item page, each backed by a typed backend call.
struct ItemDetailView: View {
    let summary: PlexMetadata
    @Environment(DemoSession.self) private var session
    @State private var item: PlexMetadata?
    @State private var children = PagedItemsModel()
    @State private var extras: [PlexMetadata] = []
    @State private var related: [PlexHub] = []
    @State private var mediaIndex = 0
    @State private var playback: PlaybackRequest?
    @State private var showDownload = false
    @State private var showSubtitles = false
    @State private var confirmDelete = false
    @State private var error: String?

    var body: some View {
        let current = item ?? summary
        List {
            DetailHeader(item: current)
            DetailActions(item: current, play: { play([current]) }, playAll: { shuffle in Task { await playAll(current, shuffle: shuffle) } })
            if let error { Text(error).foregroundStyle(.secondary) }
            if let next = current.onDeck.first {
                Section("Up next") { NavigationLink(value: next) { MediaRow(item: next) } }
            }
            if current.hasChildren { ChildrenSection(parent: current, model: children) }
            if !current.media.isEmpty {
                MediaInfoSection(item: current, mediaIndex: $mediaIndex)
                Section {
                    Button("Download for offline", systemImage: "arrow.down.circle") { showDownload = true }
                        .accessibilityIdentifier("plex.download")
                    Button("Find subtitles online", systemImage: "captions.bubble") { showSubtitles = true }
                }
            }
            if !current.roles.isEmpty || !current.directors.isEmpty { CastSection(item: current) }
            if !extras.isEmpty {
                Section("Extras") {
                    ForEach(extras) { extra in
                        Button { play([extra]) } label: { MediaRow(item: extra) }.buttonStyle(.plain)
                    }
                }
            }
            ForEach(related) { hub in
                Section { HubShelf(title: hub.title, items: hub.metadata).listRowInsets(EdgeInsets()) }
            }
        }
        .navigationTitle(current.title)
        .toolbar { DetailAdminMenu(item: current, confirmDelete: $confirmDelete) }
        .confirmationDialog("Delete this item and its files from the server?", isPresented: $confirmDelete) {
            Button("Delete from server", role: .destructive) {
                Task { _ = await session.run { try await $0.deleteItem(ratingKey: current.ratingKey) } }
            }
        }
        .task(id: [summary.ratingKey, session.revision.uuidString]) { await load() }
        .sheet(item: $playback) { PlayerView(request: $0) }
        .sheet(isPresented: $showDownload) { DownloadPlanSheet(item: current, mediaIndex: mediaIndex) }
        .sheet(isPresented: $showSubtitles) { SubtitleSearchSheet(item: current) }
    }

    private func play(_ items: [PlexMetadata]) {
        playback = PlaybackRequest(items: items, mediaIndex: mediaIndex, serverID: session.serverID)
    }

    /// Server-side play queue: a show plays from its next episode, a playlist in order, a collection by its items.
    private func playAll(_ parent: PlexMetadata, shuffle: Bool) async {
        let key = parent.ratingKey
        let source: PlexPlayQueueSource = switch parent.type {
        case "playlist": .playlist(key)
        case "collection": .items(children.items.map(\.ratingKey))
        default: .path("/library/metadata/\(key)/children")
        }
        let start = shuffle ? nil : parent.onDeck.first?.ratingKey
        var queue: PlexPlayQueue?
        _ = await session.run { queue = try await $0.createPlayQueue(source: source, shuffle: shuffle, startingRatingKey: start) }
        if let items = queue?.items, !items.isEmpty { play(items) }
    }

    private func load() async {
        guard let api = session.api else { return }
        let key = summary.ratingKey
        error = nil
        do {
            let loaded = summary.type == "playlist" ? try await api.playlist(id: key) : try await api.metadata(ratingKey: key)
            item = loaded
            mediaIndex = min(mediaIndex, max(loaded.media.count - 1, 0))
            if loaded.hasChildren {
                await children.load(api: api) { api, page in
                    switch loaded.type {
                    case "collection": try await api.collectionItems(collectionID: key, page: page)
                    case "playlist": try await api.playlistItems(id: key, page: page)
                    default: try await api.children(ratingKey: key, page: page)
                    }
                }
            }
            if ["movie", "show"].contains(loaded.type) {
                extras = (try? await api.extras(ratingKey: key).metadata) ?? []
                related = (try? await api.relatedHubs(ratingKey: key, count: 10)) ?? []
            }
        } catch is CancellationError {
        } catch {
            self.error = DemoSession.message(for: error)
        }
    }
}

/// Artwork, title, ratings, summary and genres.
struct DetailHeader: View {
    let item: PlexMetadata

    var body: some View {
        Section {
            HStack(alignment: .top, spacing: 16) {
                PlexArtwork(path: item.posterPath, width: 110, height: 165)
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title).font(.title2.bold())
                    Text(item.detailLine).foregroundStyle(.secondary)
                    if let tagline = item.tagline { Text(tagline).italic().font(.callout) }
                    if let duration = item.duration {
                        Text(Duration.milliseconds(duration), format: .units(allowed: [.hours, .minutes], width: .abbreviated))
                            .font(.caption)
                    }
                    if let rating = item.audienceRating { Label(rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill").font(.caption) }
                    if let progress = item.progress { ProgressView(value: progress) { Text("Resume") } }
                }
            }
            if let summary = item.summary, !summary.isEmpty { Text(summary) }
            if !item.genres.isEmpty { Text(item.genres.map(\.tag).formatted()).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

/// Play, watched state, rating, Continue Watching and playlist/collection membership.
struct DetailActions: View {
    let item: PlexMetadata
    let play: () -> Void
    let playAll: (Bool) -> Void
    @Environment(DemoSession.self) private var session

    var body: some View {
        let watched = session.localWatchedState(of: item) ?? item.isWatched
        Section {
            if item.isPlayable {
                Button(item.progress == nil ? "Play" : "Resume", systemImage: "play.fill", action: play)
                    .accessibilityIdentifier("plex.play")
            }
            if item.hasChildren {
                Button("Play all", systemImage: "play.fill") { playAll(false) }
                Button("Shuffle", systemImage: "shuffle") { playAll(true) }
            }
            if item.type != "playlist", item.type != "collection" {
                Button(watched ? "Mark as unwatched" : "Mark as watched", systemImage: watched ? "eye.slash" : "checkmark.circle") {
                    Task { await session.setWatched(!watched, ratingKey: item.ratingKey) }
                }
                .accessibilityIdentifier("plex.toggleWatched")
                RatingMenu(item: item)
            }
            if item.progress != nil {
                Button("Remove from Continue Watching", systemImage: "minus.circle") {
                    Task { _ = await session.run { try await $0.removeFromContinueWatching(ratingKey: item.ratingKey) } }
                }
            }
            if ["movie", "episode", "show", "season"].contains(item.type) { AddToPlaylistMenu(item: item) }
            if ["movie", "show"].contains(item.type), let sectionID = item.librarySectionID {
                AddToCollectionMenu(item: item, sectionID: sectionID)
            }
            if pendingCount > 0 {
                Label("Waiting to sync watch changes", systemImage: "arrow.triangle.2.circlepath").foregroundStyle(.secondary)
            }
        }
    }

    private var pendingCount: Int { session.pendingSync.filter { $0.ratingKey == item.ratingKey }.count }
}

/// A five-star control that stores Plex's 0–10 user rating.
struct RatingMenu: View {
    let item: PlexMetadata
    @Environment(DemoSession.self) private var session

    var body: some View {
        Menu {
            ForEach(1...5, id: \.self) { stars in
                Button { rate(Double(stars * 2)) } label: { Text("^[\(stars) star](inflect: true)") }
            }
            Button("Clear rating", role: .destructive) { rate(nil) }
        } label: {
            Label(item.userRating.map { String(localized: "Your rating: \(Int($0 / 2)) of 5") } ?? String(localized: "Rate"), systemImage: "star")
        }
    }

    private func rate(_ value: Double?) {
        Task { _ = await session.run { try await $0.rate(ratingKey: item.ratingKey, rating: value) } }
    }
}

/// Collections in the item's library section, plus a new one containing the item.
struct AddToCollectionMenu: View {
    let item: PlexMetadata
    let sectionID: String
    @Environment(DemoSession.self) private var session
    @State private var collections: [PlexMetadata] = []

    var body: some View {
        Menu("Add to collection", systemImage: "rectangle.stack.badge.plus") {
            ForEach(collections) { collection in
                Button(collection.title) {
                    Task { _ = await session.run { try await $0.addToCollection(collectionID: collection.ratingKey, ratingKeys: [item.ratingKey]) } }
                }
            }
            Button("New collection with this item", systemImage: "plus") {
                let type = item.type == "show" ? 2 : 1
                Task { _ = await session.run { _ = try await $0.createCollection(sectionID: sectionID, title: item.title, type: type, ratingKeys: [item.ratingKey]) } }
            }
        }
        .task(id: session.revision) { collections = (try? await session.api?.collections(sectionID: sectionID, page: nil).metadata) ?? [] }
    }
}

/// Seasons, episodes, collection members or playlist entries. Swipe removes collection and playlist entries.
struct ChildrenSection: View {
    let parent: PlexMetadata
    let model: PagedItemsModel
    @Environment(DemoSession.self) private var session

    var body: some View {
        Section {
            ForEach(model.items, id: \.listID) { child in
                NavigationLink(value: child) { MediaRow(item: child, watchedOverride: session.localWatchedState(of: child)) }
                    .swipeActions {
                        if ["playlist", "collection"].contains(parent.type) {
                            Button("Remove", role: .destructive) { Task { await remove(child) } }
                        }
                    }
            }
            if model.canLoadMore { Button("Load more") { Task { await model.loadMore() } } }
            if model.loading, model.items.isEmpty { ProgressView() }
        } header: {
            Text(parent.type == "show" ? "Seasons" : parent.type == "season" ? "Episodes" : "Items")
        }
    }

    private func remove(_ child: PlexMetadata) async {
        let removed = await session.run { api in
            if parent.type == "playlist", let entry = child.playlistItemID {
                try await api.removeFromPlaylist(id: parent.ratingKey, playlistItemID: entry)
            } else {
                try await api.removeFromCollection(collectionID: parent.ratingKey, ratingKey: child.ratingKey)
            }
        }
        if removed { model.remove(child) }
    }
}

/// Cast and directors; each opens everything that person appears in.
struct CastSection: View {
    let item: PlexMetadata

    var body: some View {
        Section("Cast and crew") {
            ForEach(item.directors + item.roles, id: \.self) { person in
                NavigationLink(value: PersonDestination(tag: person)) {
                    HStack {
                        Text(person.tag)
                        Spacer()
                        Text(person.role ?? String(localized: "Director")).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

/// Refresh and delete; these need a server admin.
struct DetailAdminMenu: View {
    let item: PlexMetadata
    @Binding var confirmDelete: Bool
    @Environment(DemoSession.self) private var session

    var body: some View {
        Menu("More", systemImage: "ellipsis.circle") {
            Button("Refresh metadata", systemImage: "arrow.clockwise") {
                Task { _ = await session.run { try await $0.refreshMetadata(ratingKey: item.ratingKey) } }
            }
            if item.type == "playlist" {
                Button("Delete playlist", systemImage: "trash", role: .destructive) {
                    Task { _ = await session.run { try await $0.deletePlaylist(id: item.ratingKey) } }
                }
            } else if item.type == "collection" {
                Button("Delete collection", systemImage: "trash", role: .destructive) {
                    Task { _ = await session.run { try await $0.deleteCollection(collectionID: item.ratingKey) } }
                }
            } else {
                Button("Delete from server", systemImage: "trash", role: .destructive) { confirmDelete = true }
            }
        }
    }
}

#Preview("Movie") {
    NavigationStack { ItemDetailView(summary: PlexMetadata(ratingKey: "100", title: "The Sample Movie", type: "movie")).plexDestinations() }
        .environment(DemoSession.preview())
}

#Preview("Show") {
    NavigationStack { ItemDetailView(summary: PlexMetadata(ratingKey: "200", title: "The Sample Show", type: "show")).plexDestinations() }
        .environment(DemoSession.preview())
}

#Preview("Header") {
    List { DetailHeader(item: PlexMetadata(ratingKey: "1", title: "Preview", type: "movie", summary: "Summary", year: 2026)) }
        .environment(DemoSession.preview())
}

#Preview("Rating") { RatingMenu(item: PlexMetadata(ratingKey: "1", title: "Preview", type: "movie")).environment(DemoSession.preview()) }
