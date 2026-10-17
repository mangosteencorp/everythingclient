import Plex_Shared_Backend
import SwiftUI

/// Plezy-style offline library: downloaded items play without a connection, watch changes made
/// while offline are queued, and transfers can be paused, resumed, retried or removed.
struct DownloadsView: View {
    @Environment(DemoSession.self) private var session
    @State private var playback: PlaybackRequest?

    var body: some View {
        let transfers = session.transfers
        NavigationStack {
            List {
                if !transfers.offlineItems.isEmpty {
                    Section("Available offline") {
                        ForEach(transfers.offlineItems) { download in
                            OfflineItemRow(download: download) {
                                guard let item = download.item else { return }
                                playback = PlaybackRequest(items: [item], localFile: transfers.fileURL(for: download), serverID: download.serverID)
                            }
                        }
                    }
                }
                let active = transfers.downloads.filter { $0.status != .completed || $0.item == nil }
                if !active.isEmpty {
                    Section("Transfers") {
                        ForEach(active) { DownloadRow(download: $0, transfers: transfers) }
                    }
                }
                Section {
                    LabeledContent("Watch changes waiting to sync", value: session.pendingSync.count.formatted())
                    Button("Sync now", systemImage: "arrow.triangle.2.circlepath") { Task { await session.syncNow() } }
                        .disabled(session.api == nil || session.isOffline || session.pendingSync.isEmpty)
                } footer: {
                    Text("Downloads keep the original file and its details, so they play without a connection. Keep the app open while transfers run.")
                }
                if let error = transfers.storageError { Text(error).foregroundStyle(.red) }
            }
            .overlay {
                if transfers.downloads.isEmpty {
                    ContentUnavailableView("No downloads yet", systemImage: "arrow.down.circle",
                                           description: Text("Open a movie or episode and choose Download for offline."))
                }
            }
            .statusBanner()
            .navigationTitle("Downloads")
            .sheet(item: $playback) { PlayerView(request: $0) }
            .task { await session.refreshPendingSync() }
        }
    }
}

/// A downloaded item: play locally, change watched state (queued until its server is reachable), or remove.
struct OfflineItemRow: View {
    let download: DemoDownload
    let play: () -> Void
    @Environment(DemoSession.self) private var session
    @State private var confirmRemoval = false

    var body: some View {
        if let item = download.item {
            Button(action: play) {
                MediaRow(item: item, watchedOverride: session.localWatchedState(serverID: download.serverID, ratingKey: item.ratingKey))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("plex.offlineItem")
            .contextMenu {
                Button("Mark as watched", systemImage: "checkmark.circle") {
                    Task { await session.setWatched(true, ratingKey: item.ratingKey, serverID: download.serverID) }
                }
                Button("Mark as unwatched", systemImage: "eye.slash") {
                    Task { await session.setWatched(false, ratingKey: item.ratingKey, serverID: download.serverID) }
                }
                ShareLink("Export file", item: session.transfers.fileURL(for: download))
                Button("Remove download", systemImage: "trash", role: .destructive) { confirmRemoval = true }
            }
            .confirmationDialog("Remove this downloaded file?", isPresented: $confirmRemoval) {
                Button("Remove download", role: .destructive) { session.transfers.removeCompleted(download.id) }
            }
        }
    }
}

/// A transfer with progress and pause/resume/cancel/retry controls.
struct DownloadRow: View {
    let download: DemoDownload
    let transfers: DemoTransfers
    @State private var confirmRemoval = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(download.title).font(.headline)
            Text(statusLabel).font(.caption).foregroundStyle(.secondary)
            if download.status == .downloading {
                if let progress = download.progress { ProgressView(value: progress) } else { ProgressView() }
                Text(download.received, format: .byteCount(style: .file)).font(.caption)
            }
            if let message = download.message { Text(message).font(.caption).foregroundStyle(.red) }
            HStack {
                switch download.status {
                case .queued:
                    Button("Cancel") { transfers.cancel(download.id) }
                case .pausing:
                    ProgressView("Pausing…")
                    Button("Cancel") { transfers.cancel(download.id) }
                case .downloading:
                    Button("Pause") { transfers.pause(download.id) }
                    Button("Cancel") { transfers.cancel(download.id) }
                case .paused:
                    Button("Resume") { transfers.start(download.id) }.disabled(!transfers.canRestart(download.id))
                    Button("Cancel") { transfers.cancel(download.id) }
                case .failed, .cancelled:
                    Button("Retry") { transfers.start(download.id) }.disabled(!transfers.canRestart(download.id))
                case .completed:
                    ShareLink("Export file", item: transfers.fileURL(for: download))
                    Button("Remove", role: .destructive) { confirmRemoval = true }
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 6)
        .confirmationDialog("Remove this downloaded file?", isPresented: $confirmRemoval) {
            Button("Remove", role: .destructive) { transfers.removeCompleted(download.id) }
        }
    }

    private var statusLabel: LocalizedStringResource {
        switch download.status {
        case .queued: "Queued"
        case .pausing: "Pausing"
        case .downloading: "Downloading"
        case .paused: "Paused"
        case .completed: "Completed"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }
}

#Preview { DownloadsView().environment(DemoSession.preview()) }
#Preview("Transfer row") {
    DownloadRow(download: DemoDownload(id: UUID(), title: "Sample Movie", fileName: "preview.mp4", status: .paused), transfers: DemoTransfers())
        .padding()
}

#Preview("Offline row") {
    let item = PlexMetadata(ratingKey: "100", title: "The Sample Movie", type: "movie", year: 2026)
    List { OfflineItemRow(download: DemoDownload(id: UUID(), title: item.title, fileName: "a.mp4", status: .completed, item: item)) {} }
        .environment(DemoSession.preview())
}
