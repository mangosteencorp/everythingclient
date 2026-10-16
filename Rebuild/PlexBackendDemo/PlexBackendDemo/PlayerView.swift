import AVFoundation
import AVKit
import Observation
import Plex_Shared_Backend
import SwiftUI

/// Wraps AVFoundation so playback can be replaced in tests.
protocol DemoPlayerCreating {
    func player(for request: URLRequest) -> AVPlayer
}

struct DemoPlayerFactory: DemoPlayerCreating {
    /// Plex credentials travel in headers; the asset forwards them to every playlist, segment and file request.
    func player(for request: URLRequest) -> AVPlayer {
        guard let url = request.url else { return AVPlayer() }
        let headers = request.allHTTPHeaderFields ?? [:]
        let asset = AVURLAsset(url: url, options: headers.isEmpty ? nil : ["AVURLAssetHTTPHeaderFieldsKey": headers])
        return AVPlayer(playerItem: AVPlayerItem(asset: asset))
    }
}

/// Plays one item or a play queue: direct play for AVFoundation-friendly originals, HLS transcode otherwise.
/// Reports `/:/timeline` progress every 10 seconds and on stop; offline stops are queued for sync.
@MainActor
@Observable
final class PlayerModel {
    private(set) var player: AVPlayer?
    private(set) var current: PlexMetadata?
    private(set) var index = 0
    private(set) var position: Int64 = 0
    private(set) var error: String?
    @ObservationIgnored private var observer: Any?
    @ObservationIgnored private var lastReport = Date.distantPast
    @ObservationIgnored private var transcodeSession: String?
    @ObservationIgnored private var request: PlaybackRequest?

    var activeMarker: PlexMarker? { current?.markers.first { position >= $0.startTimeOffset && position < $0.endTimeOffset } }
    var hasNext: Bool { (request?.items.count ?? 0) > index + 1 }

    static func canDirectPlay(_ version: PlexMediaVersion) -> Bool {
        ["mp4", "m4v", "mov"].contains(version.container?.lowercased() ?? "")
            && ["h264", "hevc", nil].contains(version.videoCodec?.lowercased())
    }

    func start(_ request: PlaybackRequest, at index: Int = 0, session: DemoSession, factory: any DemoPlayerCreating) async {
        self.request = request
        self.index = index
        error = nil
        var item = request.items[index]
        do {
            let urlRequest: URLRequest
            if let file = request.localFile {
                urlRequest = URLRequest(url: file)
            } else {
                guard let api = session.api else { throw PlexAPIError.offline }
                if item.media.isEmpty { item = try await api.metadata(ratingKey: item.ratingKey) }
                let mediaIndex = item.media.indices.contains(request.mediaIndex) ? request.mediaIndex : 0
                guard let version = item.media.indices.contains(mediaIndex) ? item.media[mediaIndex] : nil,
                      let part = version.parts.first else { throw PlexAPIError.noDownloadableMedia }
                if Self.canDirectPlay(version) {
                    urlRequest = try api.directPlayRequest(part: part)
                } else {
                    let session = UUID().uuidString
                    transcodeSession = session
                    urlRequest = try api.streamRequest(PlexStreamOptions(ratingKey: item.ratingKey, mediaIndex: mediaIndex, session: session))
                }
            }
            current = item
            if request.localFile == nil { session.curlLogger.log(urlRequest) }
            let player = factory.player(for: urlRequest)
            if let offset = item.viewOffset, (item.progress ?? 0) < 0.95 {
                await player.seek(to: CMTime(value: offset, timescale: 1000))
            }
            observe(player, session: session)
            self.player = player
            player.play()
        } catch {
            current = item
            self.error = DemoSession.message(for: error)
        }
    }

    func skip(_ marker: PlexMarker) {
        player?.seek(to: CMTime(value: marker.endTimeOffset, timescale: 1000))
    }

    func next(session: DemoSession, factory: any DemoPlayerCreating) async {
        guard let request, hasNext else { return }
        await stop(session: session)
        await start(request, at: index + 1, session: session, factory: factory)
    }

    func stop(session: DemoSession) async {
        guard let player, let item = current else { return }
        player.pause()
        if let observer { player.removeTimeObserver(observer) }
        observer = nil
        self.player = nil
        await session.reportProgress(
            ratingKey: item.ratingKey, state: .stopped, time: position, duration: item.duration, serverID: request?.serverID
        )
        if let transcodeSession {
            self.transcodeSession = nil
            _ = try? await session.api?.stopStream(session: transcodeSession)
        }
    }

    private func observe(_ player: AVPlayer, session: DemoSession) {
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: .main) { [weak self] time in
            MainActor.assumeIsolated { self?.tick(time, player: player, session: session) }
        }
    }

    private func tick(_ time: CMTime, player: AVPlayer, session: DemoSession) {
        guard time.isNumeric, let item = current else { return }
        position = Int64(time.seconds * 1000)
        guard Date().timeIntervalSince(lastReport) >= 10 else { return }
        lastReport = Date()
        let state: PlexPlaybackState = player.timeControlStatus == .paused ? .paused : .playing
        let position = position
        Task { await session.reportProgress(ratingKey: item.ratingKey, state: state, time: position, duration: item.duration, serverID: request?.serverID) }
    }
}

struct PlayerView: View {
    let request: PlaybackRequest
    var factory: any DemoPlayerCreating = DemoPlayerFactory()
    @Environment(DemoSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var model = PlayerModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                VideoPlayer(player: model.player)
                    .frame(minHeight: 240)
                    .overlay(alignment: .bottomTrailing) {
                        if let marker = model.activeMarker {
                            Button(marker.type == "credits" ? "Skip credits" : "Skip intro") { model.skip(marker) }
                                .buttonStyle(.borderedProminent).padding()
                        }
                    }
                if let item = model.current { Text(item.title).font(.headline) }
                if let error = model.error { Text(error).foregroundStyle(.red).padding(.horizontal) }
                if model.hasNext {
                    Button("Next in queue", systemImage: "forward.end.fill") { Task { await model.next(session: session, factory: factory) } }
                }
                Text("Progress is reported to your server while online and queued for sync when offline.")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            }
            .navigationTitle("Now playing")
            .toolbar { Button("Done") { dismiss() } }
            .task { await model.start(request, session: session, factory: factory) }
            .onDisappear { Task { await model.stop(session: session) } }
        }
        .frame(minWidth: 340, minHeight: 420)
    }
}

#Preview {
    PlayerView(request: PlaybackRequest(items: [PlexMetadata(ratingKey: "100", title: "The Sample Movie", type: "movie")]))
        .environment(DemoSession.preview())
}
