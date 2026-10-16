import Plex_Shared_Backend
import SwiftUI

/// Server status, preferences, activities, library maintenance, Live TV, notifications and a raw request console.
struct ServerToolsView: View {
    @Environment(DemoSession.self) private var session
    @State private var info: PlexServerInfo?
    @State private var threshold: Double?
    @State private var activities: [PlexActivity] = []
    @State private var dvrCount: Int?

    var body: some View {
        Form {
            Section("Server") {
                if let info {
                    LabeledContent("Name", value: info.friendlyName ?? session.serverName)
                    LabeledContent("Version", value: info.version ?? "")
                    LabeledContent("Platform", value: info.platform ?? "")
                    LabeledContent("Video transcoding", value: info.transcoderVideo ? String(localized: "Available") : String(localized: "Unavailable"))
                }
                if let threshold { LabeledContent("Counts as watched at") { Text(threshold, format: .percent) } }
                if let dvrCount { LabeledContent("Live TV DVRs", value: dvrCount.formatted()) }
            }
            Section("Activities") {
                if activities.isEmpty { Text("No background activity.").foregroundStyle(.secondary) }
                ForEach(activities) { activity in
                    VStack(alignment: .leading) {
                        Text(activity.title ?? activity.type ?? activity.uuid)
                        if let progress = activity.progress { ProgressView(value: Double(progress), total: 100) }
                    }
                    .swipeActions {
                        if activity.cancellable {
                            Button("Cancel", role: .destructive) {
                                Task { if await session.run({ try await $0.cancelActivity(uuid: activity.uuid) }) { await load() } }
                            }
                        }
                    }
                }
            }
            Section("Library maintenance") {
                ForEach(session.libraries) { library in
                    Menu(library.title) {
                        Button("Scan for new files") { maintain { try await $0.scanLibrary(sectionID: library.key, force: false) } }
                        Button("Refresh all metadata") { maintain { try await $0.scanLibrary(sectionID: library.key, force: true) } }
                        Button("Analyze media") { maintain { try await $0.analyzeLibrary(sectionID: library.key) } }
                        Button("Empty trash", role: .destructive) { maintain { try await $0.emptyTrash(sectionID: library.key) } }
                    }
                }
            }
            NotificationsSection()
            RawRequestSection()
            Section {
                Button("Clear offline cache", role: .destructive) { Task { await session.clearCache() } }
            } footer: {
                Text("Downloads and queued watch changes are kept.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Server tools")
        .task(id: session.revision) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        guard let api = session.api else { return }
        info = try? await api.serverInfo()
        threshold = try? await api.watchedThreshold()
        activities = (try? await api.activities()) ?? []
        dvrCount = (try? await api.dvrs())?.count
    }

    private func maintain(_ work: @escaping (PlexAPIService) async throws -> Void) {
        Task { if await session.run(work) { await load() } }
    }
}

/// Listens to `/:/eventsource/notifications` while visible.
struct NotificationsSection: View {
    @Environment(DemoSession.self) private var session
    private struct Event: Identifiable {
        let id = UUID()
        let text: String
    }

    @State private var listening = false
    @State private var events: [Event] = []
    @State private var task: Task<Void, Never>?

    var body: some View {
        Section("Live notifications") {
            Toggle("Listen for server events", isOn: Binding(get: { listening }, set: { $0 ? start() : stop() }))
                .disabled(session.api == nil || session.isSample || session.isOffline)
            ForEach(events) { event in
                Text(event.text).font(.system(.caption, design: .monospaced)).lineLimit(4)
            }
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        guard let request = try? session.api?.notificationsRequest() else { return }
        listening = true
        task = Task {
            do {
                for try await event in PlexEventSource(logger: session.curlLogger).events(for: request) {
                    let body = session.formatted(PlexHTTPResult(data: event.data, statusCode: 200))
                    events.insert(Event(text: "\(event.name): \(body)"), at: 0)
                    events = Array(events.prefix(20))
                }
            } catch {}
            listening = false
        }
    }

    private func stop() {
        task?.cancel()
        task = nil
        listening = false
    }
}

/// Sends any server-relative request through the same credential, proxy and redirect rules as typed calls.
struct RawRequestSection: View {
    @Environment(DemoSession.self) private var session
    @State private var method = PlexHTTPMethod.get
    @State private var path = "/identity"
    @State private var response = ""
    @State private var confirm = false

    var body: some View {
        Section {
            Picker("Method", selection: $method) {
                ForEach(PlexHTTPMethod.allCases, id: \.self) { Text(verbatim: $0.rawValue).tag($0) }
            }
            TextField("Server-relative path", text: $path).autocorrectionDisabled().accessibilityIdentifier("plex.requestPath")
            Button("Send request") { if method == .get { send() } else { confirm = true } }
                .disabled(session.api == nil || path.isEmpty)
                .accessibilityIdentifier("plex.sendRequest")
            if !response.isEmpty {
                Text(response).font(.system(.caption, design: .monospaced)).textSelection(.enabled).lineLimit(30)
                    .accessibilityIdentifier("plex.response")
            }
        } header: {
            Text("Raw request")
        } footer: {
            Text("For endpoints without a typed API. Tokens are redacted from responses.")
        }
        .confirmationDialog("This request may change data on your server.", isPresented: $confirm) {
            Button("Send request", role: .destructive, action: send)
        }
    }

    private func send() {
        let method = method
        let path = path
        Task {
            guard let api = session.api else { return }
            do {
                response = session.formatted(try await api.execute(path: path, method: method))
            } catch {
                response = DemoSession.message(for: error)
            }
        }
    }
}

#Preview { NavigationStack { ServerToolsView() }.environment(DemoSession.preview()) }
#Preview("Raw request") { Form { RawRequestSection() }.environment(DemoSession.preview()) }
#Preview("Notifications") { Form { NotificationsSection() }.environment(DemoSession.preview()) }
