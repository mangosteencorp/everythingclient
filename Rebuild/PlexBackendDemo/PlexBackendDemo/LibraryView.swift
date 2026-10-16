import Plex_Shared_Backend
import SwiftUI

/// Library sections, playlists and items shared with this account.
struct LibraryView: View {
    @Environment(DemoSession.self) private var session

    var body: some View {
        NavigationStack {
            Group {
                if session.api == nil {
                    ConnectPrompt()
                } else {
                    List {
                        Section("Libraries") {
                            ForEach(session.libraries) { library in
                                NavigationLink(value: library) { Label(library.title, systemImage: library.symbol) }
                            }
                        }
                        Section {
                            NavigationLink { PlaylistsView() } label: { Label("Playlists", systemImage: "music.note.list") }
                            NavigationLink {
                                PagedItemsScreen(title: String(localized: "Shared with you")) { api, page in
                                    try await api.items(sectionID: "shared", page: page)
                                }
                            } label: { Label("Shared with you", systemImage: "person.2") }
                        }
                    }
                    .overlay { if session.libraries.isEmpty { ContentUnavailableView("No libraries", systemImage: "rectangle.stack") } }
                }
            }
            .statusBanner()
            .navigationTitle("Library")
            .plexDestinations()
        }
    }
}

extension PlexLibrary {
    var symbol: String {
        switch type {
        case "movie": "film"
        case "show": "tv"
        case "artist": "music.note"
        case "photo": "photo"
        default: "rectangle.stack"
        }
    }
}

/// One library: browse with server-advertised sorts and filters, recommendations, collections and folders.
struct LibrarySectionView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case browse, recommended, collections, folders
        var id: Self { self }
        var title: LocalizedStringResource {
            switch self {
            case .browse: "Browse"
            case .recommended: "Recommended"
            case .collections: "Collections"
            case .folders: "Folders"
            }
        }
    }

    let library: PlexLibrary
    @Environment(DemoSession.self) private var session
    @State private var mode = Mode.browse
    @State private var query = PlexLibraryQuery()
    @State private var model = PagedItemsModel()
    @State private var options = LibraryOptions()

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityIdentifier("plex.sectionMode")
            if mode == .recommended {
                SectionHubsView(sectionID: library.key)
            } else {
                PagedItemsList(model: model, retry: load)
            }
        }
        .navigationTitle(library.title)
        .toolbar {
            if mode == .browse { LibraryQueryMenu(query: $query, options: options) }
        }
        .task(id: LoadKey(revision: session.revision, mode: mode, query: query)) { await load() }
        .task(id: session.revision) { options = await LibraryOptions.load(sectionID: library.key, api: session.api) }
    }

    private struct LoadKey: Equatable {
        let revision: UUID
        let mode: Mode
        let query: PlexLibraryQuery
    }

    private func load() async {
        guard let api = session.api else { return model.reset() }
        let sectionID = library.key
        let query = query
        switch mode {
        case .browse: await model.load(api: api) { try await $0.items(sectionID: sectionID, page: $1, query: query) }
        case .collections: await model.load(api: api) { try await $0.collections(sectionID: sectionID, page: $1) }
        case .folders: await model.load(api: api) { api, _ in try await api.folders(sectionID: sectionID) }
        case .recommended: model.reset()
        }
    }
}

/// Sorts, boolean filters and genre values advertised by a section.
struct LibraryOptions: Equatable {
    var sorts: [PlexDirectory] = []
    var toggles: [PlexDirectory] = []
    var genres: [PlexDirectory] = []

    static func load(sectionID: String, api: PlexAPIService?) async -> LibraryOptions {
        guard let api else { return LibraryOptions() }
        let filters = (try? await api.filters(sectionID: sectionID)) ?? []
        var options = LibraryOptions(sorts: (try? await api.sorts(sectionID: sectionID)) ?? [])
        options.toggles = filters.filter { $0.filterType == "boolean" }
        // Each filter's key lists its values; a value's key is what the items query expects.
        if let genres = filters.first(where: { $0.filter == "genre" }) {
            options.genres = (try? await api.container(key: genres.key).directories) ?? []
        }
        return options
    }
}

/// The toolbar menu that edits a `PlexLibraryQuery`.
struct LibraryQueryMenu: View {
    @Binding var query: PlexLibraryQuery
    let options: LibraryOptions

    var body: some View {
        Menu {
            if !options.sorts.isEmpty {
                Picker("Sort", selection: $query.sort) {
                    Text("Default").tag(String?.none)
                    ForEach(options.sorts) { sort in
                        Text(sort.title).tag(Optional(sort.key))
                        if let descending = sort.descKey { Text("\(sort.title) (descending)").tag(Optional(descending)) }
                    }
                }
            }
            ForEach(options.toggles) { filter in
                Toggle(filter.title, isOn: binding(for: filter.filter ?? filter.key, value: "1"))
            }
            if !options.genres.isEmpty {
                Picker("Genre", selection: genreBinding) {
                    Text("Any genre").tag(String?.none)
                    ForEach(options.genres) { Text($0.title).tag(Optional($0.key)) }
                }
            }
        } label: {
            Label("Sort and filter", systemImage: query == PlexLibraryQuery() ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
        .accessibilityIdentifier("plex.sortFilter")
    }

    private var genreBinding: Binding<String?> {
        Binding(get: { query.filters["genre"] }, set: { query.filters["genre"] = $0 })
    }

    private func binding(for name: String, value: String) -> Binding<Bool> {
        Binding(get: { query.filters[name] == value }, set: { query.filters[name] = $0 ? value : nil })
    }
}

/// The section's recommendation hubs.
struct SectionHubsView: View {
    let sectionID: String
    @Environment(DemoSession.self) private var session
    @State private var hubs: [PlexHub] = []
    @State private var error: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(hubs) { HubShelf(title: $0.title, items: $0.metadata, hub: $0) }
            }
            .padding(.vertical)
        }
        .overlay {
            if hubs.isEmpty, let error { ContentUnavailableView("Unable to load", systemImage: "exclamationmark.triangle", description: Text(error)) }
        }
        .task(id: session.revision) {
            guard let api = session.api else { return }
            do { hubs = try await api.sectionHubs(sectionID: sectionID, count: 12) } catch { self.error = DemoSession.message(for: error) }
        }
    }
}

#Preview { LibraryView().environment(DemoSession.preview()) }
#Preview("Section") {
    NavigationStack { LibrarySectionView(library: PlexLibrary(key: "1", title: "Movies", type: "movie")).plexDestinations() }
        .environment(DemoSession.preview())
}

#Preview("Query menu") {
    LibraryQueryMenu(query: .constant(PlexLibraryQuery()), options: LibraryOptions())
}
