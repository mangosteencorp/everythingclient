import Plex_Shared_Backend
import SwiftUI

/// Video playlists: open, create and delete. Items are managed from a playlist's detail screen.
struct PlaylistsView: View {
    @Environment(DemoSession.self) private var session
    @State private var model = PagedItemsModel()
    @State private var newTitle = ""
    @State private var creating = false

    var body: some View {
        PagedItemsList(model: model, retry: load)
            .navigationTitle("Playlists")
            .toolbar { Button("New playlist", systemImage: "plus") { creating = true } }
            .alert("New playlist", isPresented: $creating) {
                TextField("Name", text: $newTitle)
                Button("Create") { Task { await create() } }
                Button("Cancel", role: .cancel) { newTitle = "" }
            } message: {
                Text("Add items from any movie or episode with “Add to playlist”.")
            }
            .task(id: session.revision) { await load() }
    }

    private func load() async {
        guard let api = session.api else { return model.reset() }
        await model.load(api: api) { try await $0.playlists(type: "video", page: $1) }
    }

    private func create() async {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        newTitle = ""
        guard !title.isEmpty, await session.run({ _ = try await $0.createPlaylist(title: title, ratingKeys: []) }) else { return }
        await load()
    }
}

/// "Add to playlist": existing video playlists plus a new one containing the item.
struct AddToPlaylistMenu: View {
    let item: PlexMetadata
    @Environment(DemoSession.self) private var session
    @State private var playlists: [PlexMetadata] = []
    @State private var status: LocalizedStringResource?

    var body: some View {
        Menu("Add to playlist", systemImage: "text.badge.plus") {
            ForEach(playlists.filter { $0.smart != true }) { playlist in
                Button(playlist.title) {
                    Task { if await session.run({ try await $0.addToPlaylist(id: playlist.ratingKey, ratingKeys: [item.ratingKey]) }) { status = "Added to playlist." } }
                }
            }
            Button("New playlist with this item", systemImage: "plus") {
                Task { if await session.run({ _ = try await $0.createPlaylist(title: item.title, ratingKeys: [item.ratingKey]) }) { status = "Playlist created." } }
            }
        }
        .task(id: session.revision) { playlists = (try? await session.api?.playlists(type: "video", page: nil).metadata) ?? [] }
        .alert(status.map { String(localized: $0) } ?? "", isPresented: Binding(get: { status != nil }, set: { if !$0 { status = nil } })) {}
    }
}

#Preview { NavigationStack { PlaylistsView().plexDestinations() }.environment(DemoSession.preview()) }
#Preview("Add to playlist") {
    AddToPlaylistMenu(item: PlexMetadata(ratingKey: "100", title: "The Sample Movie", type: "movie")).environment(DemoSession.preview())
}
