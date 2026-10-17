import Foundation

/// A watch-state change made while offline, waiting to be pushed to its server.
public struct PlexPendingWatchAction: Codable, Sendable, Equatable, Identifiable {
    /// What changed.
    public enum Kind: Codable, Sendable, Equatable {
        /// Marked as watched.
        case watched
        /// Marked as unwatched.
        case unwatched
        /// Milliseconds, as reported by the player.
        case progress(viewOffset: Int64, duration: Int64?)
    }

    /// A unique ID for this queued change.
    public let id: UUID
    /// The server that owns the item (its machine identifier).
    public let serverID: String
    /// The item on that server.
    public let ratingKey: String
    /// The change to replay.
    public let kind: Kind
    /// When the change happened; progress is replayed with this time.
    public let recordedAt: Date
    /// Failed sync attempts so far.
    public internal(set) var attempts: Int
}

/// Plezy's offline watch sync: queue watched, unwatched and progress changes, persist them, and replay
/// them oldest-first when the server is reachable. Progress past the server's threshold also marks the item
/// watched. Failed actions stay queued; after `maxAttempts` they are kept but no longer retried.
public actor PlexWatchSyncQueue {
    /// After this many failures an action stays queued but is no longer retried, matching Plezy.
    public static let maxAttempts = 5
    private let fileURL: URL
    private var actions: [PlexPendingWatchAction]

    /// Opens a queue persisted as JSON at `fileURL`, loading anything saved there.
    public init(fileURL: URL) {
        self.fileURL = fileURL
        actions = (try? JSONDecoder().decode([PlexPendingWatchAction].self, from: Data(contentsOf: fileURL))) ?? []
    }

    /// Queued changes, oldest first, for one server or for all when `serverID` is nil.
    public func pending(serverID: String? = nil) -> [PlexPendingWatchAction] {
        actions.filter { serverID == nil || $0.serverID == serverID }
    }

    /// The locally known watched state for an item, if a queued action decides it.
    public func localWatchedState(serverID: String, ratingKey: String) -> Bool? {
        switch actions.last(where: { $0.serverID == serverID && $0.ratingKey == ratingKey })?.kind {
        case .watched: true
        case .unwatched: false
        default: nil
        }
    }

    /// Progress replaces earlier progress for the same item; watched/unwatched replaces everything earlier.
    public func enqueue(_ kind: PlexPendingWatchAction.Kind, serverID: String, ratingKey: String, at date: Date = .now) {
        actions.removeAll { action in
            guard action.serverID == serverID, action.ratingKey == ratingKey else { return false }
            if case .progress = kind, case .progress = action.kind { return true }
            if case .progress = kind { return false }
            return true
        }
        actions.append(PlexPendingWatchAction(id: UUID(), serverID: serverID, ratingKey: ratingKey, kind: kind, recordedAt: date, attempts: 0))
        save()
    }

    /// Discards every queued change.
    public func removeAll() {
        actions = []
        save()
    }

    /// Pushes this server's queue. Returns how many actions were synced.
    @discardableResult
    public func sync(serverID: String, using service: any PlexWatchStateServing) async -> Int {
        guard actions.contains(where: { $0.serverID == serverID && $0.attempts < Self.maxAttempts }) else { return 0 }
        let threshold = (try? await service.watchedThreshold()) ?? 0.9
        var synced = 0
        for action in actions where action.serverID == serverID && action.attempts < Self.maxAttempts {
            do {
                try await push(action, using: service, threshold: threshold)
                actions.removeAll { $0.id == action.id }
                synced += 1
            } catch {
                if let index = actions.firstIndex(where: { $0.id == action.id }) { actions[index].attempts += 1 }
            }
        }
        save()
        return synced
    }

    private func push(_ action: PlexPendingWatchAction, using service: any PlexWatchStateServing, threshold: Double) async throws {
        switch action.kind {
        case .watched: try await service.markWatched(ratingKey: action.ratingKey)
        case .unwatched: try await service.markUnwatched(ratingKey: action.ratingKey)
        case let .progress(viewOffset, duration):
            let finished = duration.map { $0 > 0 && Double(viewOffset) / Double($0) >= threshold } ?? false
            try await service.reportTimeline(
                ratingKey: action.ratingKey, state: .stopped, time: finished ? duration ?? viewOffset : viewOffset,
                duration: duration, recordedAt: action.recordedAt
            )
            if finished { try await service.markWatched(ratingKey: action.ratingKey) }
        }
    }

    private func save() {
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(actions).write(to: fileURL, options: .atomic)
    }
}
