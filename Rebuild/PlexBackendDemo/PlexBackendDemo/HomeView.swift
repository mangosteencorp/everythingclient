import Plex_Shared_Backend
import SwiftUI

/// Continue Watching (merged with On Deck) and the server's home hubs, like Plezy's home screen.
struct HomeView: View {
    @Environment(DemoSession.self) private var session
    @State private var continueWatching: [PlexMetadata] = []
    @State private var hubs: [PlexHub] = []
    @State private var loaded = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if session.api == nil {
                    if session.isConnecting { ProgressView("Connecting to your Plex server…") } else { ConnectPrompt() }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            if !continueWatching.isEmpty {
                                HubShelf(title: String(localized: "Continue Watching"), items: continueWatching)
                                    .accessibilityIdentifier("plex.continueWatching")
                            }
                            ForEach(hubs) { hub in HubShelf(title: hub.title, items: hub.metadata, hub: hub) }
                        }
                        .padding(.vertical)
                    }
                    .overlay { HomeState(loaded: loaded, isEmpty: hubs.isEmpty && continueWatching.isEmpty, error: error) }
                    .refreshable { await load() }
                }
            }
            .statusBanner()
            .navigationTitle(session.serverName.isEmpty ? String(localized: "Home") : session.serverName)
            .plexDestinations()
            .task(id: session.revision) { await load() }
        }
    }

    private func load() async {
        guard let api = session.api else { return }
        error = nil
        async let recent = api.continueWatching(count: 20)
        async let shelves = api.homeHubs(count: 12)
        do {
            (continueWatching, hubs) = try await (recent, shelves)
        } catch is CancellationError {
        } catch {
            self.error = DemoSession.message(for: error)
        }
        loaded = true
    }
}

private struct HomeState: View {
    let loaded: Bool
    let isEmpty: Bool
    let error: String?

    var body: some View {
        if isEmpty {
            if let error {
                ContentUnavailableView("Unable to load home", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if loaded {
                ContentUnavailableView("Nothing to show yet", systemImage: "house")
            } else {
                ProgressView()
            }
        }
    }
}

#Preview { HomeView().environment(DemoSession.preview()) }
#Preview("Empty home") { HomeState(loaded: true, isEmpty: true, error: nil) }
