import Plex_Shared_Backend
import SwiftUI

/// Server-wide search across movies, shows and collections.
struct SearchView: View {
    @Environment(DemoSession.self) private var session
    @State private var text = ""
    @State private var submitted = ""
    @State private var model = PagedItemsModel()

    var body: some View {
        NavigationStack {
            Group {
                if session.api == nil {
                    ConnectPrompt()
                } else if submitted.isEmpty {
                    ContentUnavailableView("Search your server", systemImage: "magnifyingglass",
                                           description: Text("Find movies, shows and collections."))
                } else {
                    PagedItemsList(model: model, retry: load)
                }
            }
            .statusBanner()
            .navigationTitle("Search")
            .searchable(text: $text, prompt: Text("Movies, shows and collections"))
            .onSubmit(of: .search) { submitted = text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .task(id: [submitted, session.revision.uuidString]) { await load() }
            .plexDestinations()
        }
    }

    private func load() async {
        guard let api = session.api, !submitted.isEmpty else { return model.reset() }
        let term = submitted
        await model.load(api: api) { try await $0.search(query: term, page: $1) }
    }
}

#Preview { SearchView().environment(DemoSession.preview()) }
