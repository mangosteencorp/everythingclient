import Foundation
import Plex_Shared_Backend

extension DemoSession {
    // MARK: - Offline and watch sync

    /// Cache-only browsing. Going back online reconnects when needed and pushes queued watch changes.
    func setOffline(_ offline: Bool) async {
        isOffline = offline
        cachingTransport?.isOffline = offline
        revision = UUID()
        guard !offline else { return }
        if hasAccount, connectedServerID == nil, !isSample { await refreshServers() } else { await syncNow() }
    }

    func syncNow() async {
        guard let api, !isOffline else { return }
        _ = await syncQueue.sync(serverID: serverID, using: api)
        await refreshPendingSync()
    }

    func refreshPendingSync() async {
        pendingSync = await syncQueue.pending()
    }

    func localWatchedState(of item: PlexMetadata) -> Bool? { localWatchedState(serverID: serverID, ratingKey: item.ratingKey) }

    /// The watched state decided by a queued action, if any; progress-only actions don't decide it.
    func localWatchedState(serverID: String?, ratingKey: String) -> Bool? {
        switch pendingSync.last(where: { $0.serverID == serverID && $0.ratingKey == ratingKey })?.kind {
        case .watched: true
        case .unwatched: false
        default: nil
        }
    }

    /// Online changes go to the server; offline (or failed) changes are queued like Plezy's offline watch sync.
    func setWatched(_ watched: Bool, ratingKey: String, serverID: String? = nil) async {
        let target = serverID ?? self.serverID
        if let api, !isOffline, target == self.serverID {
            do {
                if watched { try await api.markWatched(ratingKey: ratingKey) } else { try await api.markUnwatched(ratingKey: ratingKey) }
                revision = UUID()
                return
            } catch let failure where !Self.isConnectivityFailure(failure) {
                error = Self.message(for: failure)
                return
            } catch {}
        }
        await syncQueue.enqueue(watched ? .watched : .unwatched, serverID: target, ratingKey: ratingKey)
        await refreshPendingSync()
    }

    /// Player progress. Playing/paused updates are best effort; a stopped position is queued if it cannot be sent.
    func reportProgress(
        ratingKey: String, state: PlexPlaybackState, time: Int64, duration: Int64?, serverID: String? = nil
    ) async {
        let target = serverID ?? self.serverID
        if let api, !isOffline, target == self.serverID {
            do {
                try await api.reportTimeline(ratingKey: ratingKey, state: state, time: time, duration: duration, recordedAt: nil)
                return
            } catch {}
        }
        guard state == .stopped, time > 0 else { return }
        await syncQueue.enqueue(.progress(viewOffset: time, duration: duration), serverID: target, ratingKey: ratingKey)
        await refreshPendingSync()
    }

    func clearCache() async {
        await cache.removeAll()
    }
}
