import Foundation
import Observation
import Plex_Shared_Backend
import SwiftUI

typealias PlexPageFetch = (PlexAPIService, PlexPagination) async throws -> PlexMediaContainer

extension PlexMetadata {
    /// Playlists may contain the same item twice; their entries are unique by playlist item.
    var listID: String { playlistItemID ?? ratingKey }
}

/// Pages any Plex list using `X-Plex-Container-Start/Size` and the returned offset/total.
/// A newer `load` invalidates in-flight responses from the previous one.
@MainActor
@Observable
final class PagedItemsModel {
    private(set) var items: [PlexMetadata] = []
    private(set) var folders: [PlexDirectory] = []
    private(set) var total: Int?
    private(set) var loading = false
    private(set) var hasLoaded = false
    private(set) var canLoadMore = false
    private(set) var error: String?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private(set) var nextOffset = 0
    @ObservationIgnored private var source: (api: PlexAPIService, fetch: PlexPageFetch)?
    let pageSize: Int

    init(pageSize: Int = 50) { self.pageSize = pageSize }

    func reset() {
        generation = UUID()
        source = nil
        items = []
        folders = []
        total = nil
        nextOffset = 0
        canLoadMore = false
        loading = false
        hasLoaded = false
        error = nil
    }

    func load(api: PlexAPIService, fetch: @escaping PlexPageFetch) async {
        reset()
        source = (api, fetch)
        await fetchPage()
    }

    func loadMore() async {
        guard canLoadMore, !loading else { return }
        await fetchPage()
    }

    func remove(_ item: PlexMetadata) { items.removeAll { $0.listID == item.listID } }

    private func fetchPage() async {
        guard let source else { return }
        let current = generation
        loading = true
        error = nil
        defer { if generation == current { loading = false } }
        do {
            let page = try PlexPagination(start: nextOffset, size: pageSize)
            let result = try await source.fetch(source.api, page)
            guard generation == current else { return }
            var seen = Set(items.map(\.listID))
            let fresh = result.metadata.filter { seen.insert($0.listID).inserted }
            items += fresh
            if page.start == 0 { folders = result.directories }
            nextOffset = (result.offset ?? page.start) + result.metadata.count
            total = result.totalSize
            canLoadMore = !fresh.isEmpty && (result.totalSize.map { nextOffset < $0 } ?? (result.metadata.count >= page.size))
            hasLoaded = true
        } catch is CancellationError {
        } catch {
            if generation == current { self.error = DemoSession.message(for: error) }
        }
    }
}

/// Folders, items, a "load more" row and empty/error states for a `PagedItemsModel`.
struct PagedItemsList: View {
    let model: PagedItemsModel
    var retry: () async -> Void = {}
    @Environment(DemoSession.self) private var session

    var body: some View {
        List {
            if !model.folders.isEmpty {
                Section("Folders") {
                    ForEach(model.folders) { folder in
                        NavigationLink(value: folder) { Label(folder.title, systemImage: "folder") }
                    }
                }
            }
            Section {
                ForEach(model.items, id: \.listID) { item in
                    NavigationLink(value: item) { MediaRow(item: item, watchedOverride: session.localWatchedState(of: item)) }
                }
                if model.canLoadMore {
                    Button("Load more") { Task { await model.loadMore() } }
                        .disabled(model.loading)
                        .task { await model.loadMore() }
                }
            } header: {
                if let total = model.total, !model.items.isEmpty { Text("\(model.items.count) of \(total)") }
            }
        }
        .overlay { PagedItemsState(model: model, retry: retry) }
        .refreshable { await retry() }
    }
}

/// Loading, failure and empty overlays.
struct PagedItemsState: View {
    let model: PagedItemsModel
    let retry: () async -> Void

    var body: some View {
        if model.items.isEmpty, model.folders.isEmpty {
            if let error = model.error {
                ContentUnavailableView {
                    Label("Unable to load", systemImage: "exclamationmark.triangle")
                } description: { Text(error) } actions: { Button("Retry") { Task { await retry() } } }
            } else if model.hasLoaded {
                ContentUnavailableView("Nothing here yet", systemImage: "rectangle.stack")
            } else {
                ProgressView()
            }
        }
    }
}

/// A pushed list for a person, a hub's "See all", or a folder.
struct PagedItemsScreen: View {
    let title: String
    let fetch: PlexPageFetch
    @Environment(DemoSession.self) private var session
    @State private var model = PagedItemsModel()

    var body: some View {
        PagedItemsList(model: model, retry: load)
            .navigationTitle(title)
            .task(id: session.revision) { await load() }
    }

    private func load() async {
        guard let api = session.api else { return model.reset() }
        await model.load(api: api, fetch: fetch)
    }
}

#Preview("Paged list") {
    NavigationStack {
        PagedItemsScreen(title: "Movies") { api, page in try await api.items(sectionID: "1", page: page) }
            .plexDestinations()
    }
    .environment(DemoSession.preview())
}

#Preview("Empty state") { PagedItemsState(model: PagedItemsModel(), retry: {}) }
