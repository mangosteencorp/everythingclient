import Plex_Shared_Backend
import SwiftUI

extension PlexMediaVersion {
    var summary: String {
        [videoResolution.map { $0.hasSuffix("k") ? $0.uppercased() : "\($0)p" }, videoCodec?.uppercased(), container?.uppercased()]
            .compactMap { $0 }.joined(separator: " · ")
    }
}

/// Versions, audio and subtitle tracks (saved on the server with stream selection) and intro/credits markers.
struct MediaInfoSection: View {
    let item: PlexMetadata
    @Binding var mediaIndex: Int
    @Environment(DemoSession.self) private var session
    @State private var audioID: String?
    @State private var subtitleID: String?

    var body: some View {
        let part = item.media.indices.contains(mediaIndex) ? item.media[mediaIndex].parts.first : nil
        let streams = part?.streams ?? []
        Section("Media") {
            if item.media.count > 1 {
                Picker("Version", selection: $mediaIndex) {
                    ForEach(item.media.indices, id: \.self) { Text(item.media[$0].summary).tag($0) }
                }
            } else if let version = item.media.first {
                LabeledContent("Version", value: version.summary)
            }
            if let size = part?.size { LabeledContent("File size") { Text(size, format: .byteCount(style: .file)) } }
            let audio = streams.filter { $0.streamType == 2 }
            if !audio.isEmpty {
                Picker("Audio", selection: selection($audioID, part: part, audio: true)) {
                    ForEach(audio) { Text($0.displayTitle ?? $0.codec ?? "").tag(Optional($0.id)) }
                }
            }
            let subtitles = streams.filter { $0.streamType == 3 }
            if !subtitles.isEmpty {
                Picker("Subtitles", selection: selection($subtitleID, part: part, audio: false)) {
                    Text("Off").tag(Optional("0"))
                    ForEach(subtitles) { Text($0.displayTitle ?? $0.codec ?? "").tag(Optional($0.id)) }
                }
            }
            ForEach(item.markers, id: \.self) { marker in
                LabeledContent(marker.type == "intro" ? "Intro" : marker.type == "credits" ? "Credits" : marker.type) {
                    Text("\(Duration.milliseconds(marker.startTimeOffset), format: .time(pattern: .minuteSecond)) – \(Duration.milliseconds(marker.endTimeOffset), format: .time(pattern: .minuteSecond))")
                }
            }
        }
        .onChange(of: mediaIndex, initial: true) {
            audioID = streams.first { $0.streamType == 2 && $0.selected == true }?.id
            subtitleID = streams.first { $0.streamType == 3 && $0.selected == true }?.id ?? "0"
        }
    }

    /// Writes the choice back to Plex so every client (and the next playback) uses it.
    private func selection(_ value: Binding<String?>, part: PlexMediaPart?, audio: Bool) -> Binding<String?> {
        Binding(get: { value.wrappedValue }, set: { newValue in
            value.wrappedValue = newValue
            guard let partID = part?.id else { return }
            Task {
                _ = await session.run {
                    try await $0.selectStreams(partID: partID, audioStreamID: audio ? newValue : nil, subtitleStreamID: audio ? nil : newValue)
                }
            }
        })
    }
}

/// Builds an original-file download plan and queues it, including external subtitle sidecars.
struct DownloadPlanSheet: View {
    let item: PlexMetadata
    @State var mediaIndex: Int
    @Environment(DemoSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var allParts = true
    @State private var includeSubtitles = true
    @State private var plan: PlexDownloadPlan?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                if item.media.count > 1 {
                    Picker("Version", selection: $mediaIndex) {
                        ForEach(item.media.indices, id: \.self) { Text(item.media[$0].summary).tag($0) }
                    }
                }
                Toggle("Require every part", isOn: $allParts)
                Toggle("Include external subtitles", isOn: $includeSubtitles)
                if let plan {
                    Section("Planned files") {
                        ForEach(plan.parts, id: \.partIndex) { part in
                            LabeledContent("Part \(part.partIndex + 1)") {
                                if let size = part.part.size { Text(size, format: .byteCount(style: .file)) }
                            }
                            if !part.subtitles.isEmpty { Text("\(part.subtitles.count) external subtitle files").font(.caption) }
                        }
                    }
                    .accessibilityIdentifier("plex.plannedFiles")
                }
                if let error { Text(error).foregroundStyle(.red) }
                if session.isSample { Text("Connect to your server to transfer real files.").font(.caption) }
            }
            .formStyle(.grouped)
            .navigationTitle("Download")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Download") {
                        guard let plan else { return }
                        session.transfers.enqueue(plan, item: item, serverID: session.serverID, includeSubtitles: includeSubtitles)
                        dismiss()
                    }
                    .disabled(plan == nil || session.isSample)
                    .accessibilityIdentifier("plex.startDownload")
                }
            }
            .task(id: [mediaIndex, allParts ? 1 : 0]) { await makePlan() }
        }
    }

    private func makePlan() async {
        guard let api = session.api else { return }
        do {
            plan = try await api.downloadPlan(ratingKey: item.ratingKey, mediaIndex: mediaIndex, selection: allParts ? .allParts : .firstPlayable)
            error = nil
        } catch {
            plan = nil
            self.error = DemoSession.message(for: error)
        }
    }
}

/// Asks the server to search online subtitle providers, then adds the chosen subtitle to the item.
struct SubtitleSearchSheet: View {
    let item: PlexMetadata
    @Environment(DemoSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var language = Locale.current.language.languageCode?.identifier ?? "en"
    @State private var results: [PlexSubtitleSearchResult] = []
    @State private var searched = false
    @State private var added: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Language code", text: $language).autocorrectionDisabled()
                    Button("Search") { Task { await search() } }.disabled(language.isEmpty)
                }
                Section {
                    ForEach(results) { result in
                        Button {
                            Task { if await session.run({ try await $0.downloadSubtitle(ratingKey: item.ratingKey, result: result) }) { added = result.key } }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(result.displayTitle ?? result.key)
                                Text(verbatim: [result.providerTitle, result.codec?.uppercased()].compactMap { $0 }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .badge(added == result.key ? Text("Added") : nil)
                    }
                } footer: {
                    if searched, results.isEmpty { Text("No subtitles found for this language.") }
                }
            }
            .navigationTitle("Find subtitles")
            .toolbar { Button("Done") { dismiss() } }
        }
    }

    private func search() async {
        searched = false
        _ = await session.run { results = try await $0.searchSubtitles(ratingKey: item.ratingKey, language: language) }
        searched = true
    }
}

#Preview("Media info") {
    let item = PlexMetadata(ratingKey: "1", title: "Preview", type: "movie", media: [
        PlexMediaVersion(container: "mp4", videoCodec: "h264", videoResolution: "1080", parts: [PlexMediaPart(id: "1", size: 1_000_000, streams: [
            PlexMediaStream(id: "a", streamType: 2, displayTitle: "English", selected: true),
            PlexMediaStream(id: "s", streamType: 3, key: "/s", displayTitle: "English (SRT)"),
        ])]),
    ])
    List { MediaInfoSection(item: item, mediaIndex: .constant(0)) }.environment(DemoSession.preview())
}

#Preview("Download") {
    DownloadPlanSheet(item: PlexMetadata(ratingKey: "100", title: "The Sample Movie", type: "movie"), mediaIndex: 0)
        .environment(DemoSession.preview())
}

#Preview("Subtitles") {
    SubtitleSearchSheet(item: PlexMetadata(ratingKey: "100", title: "The Sample Movie", type: "movie")).environment(DemoSession.preview())
}
