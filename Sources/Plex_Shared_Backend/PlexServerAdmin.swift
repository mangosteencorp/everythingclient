import Foundation

/// `GET /` — the server's name, version and capabilities.
public struct PlexServerInfo: Decodable, Sendable, Equatable {
    /// The server's display name.
    public let friendlyName: String?
    /// The server's unique identifier.
    public let machineIdentifier: String?
    /// Plex Media Server version.
    public let version: String?
    /// Host operating system.
    public let platform: String?
    /// Whether the server can transcode video.
    public let transcoderVideo: Bool
    /// Whether the server is signed in to a Plex account.
    public let myPlex: Bool

    enum Envelope: String, CodingKey { case mediaContainer = "MediaContainer" }
    enum CodingKeys: String, CodingKey { case friendlyName, machineIdentifier, version, platform, transcoderVideo, myPlex }

    /// Decodes the `MediaContainer` of `GET /`.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: Envelope.self).nestedContainer(keyedBy: CodingKeys.self, forKey: .mediaContainer)
        friendlyName = try values.decodeIfPresent(String.self, forKey: .friendlyName)
        machineIdentifier = try values.flexibleString(forKey: .machineIdentifier)
        version = try values.flexibleString(forKey: .version)
        platform = try values.decodeIfPresent(String.self, forKey: .platform)
        transcoderVideo = try values.flexibleBool(forKey: .transcoderVideo) ?? false
        myPlex = try values.flexibleBool(forKey: .myPlex) ?? false
    }
}

/// A server or library preference. `value` is normalized to text.
public struct PlexSetting: Decodable, Sendable, Equatable, Identifiable {
    /// The preference key, such as `LibraryVideoPlayedThreshold`.
    public let id: String
    /// Human-readable name.
    public let label: String?
    /// Help text.
    public let summary: String?
    /// Value type: `bool`, `int`, `text` or `double`.
    public let type: String?
    /// Current value as text; booleans become `1` or `0`.
    public let value: String?

    enum CodingKeys: String, CodingKey { case id, label, summary, type, value }

    /// Decodes a setting, normalizing number and boolean values to text.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.requiredString(forKey: .id)
        label = try values.decodeIfPresent(String.self, forKey: .label)
        summary = try values.decodeIfPresent(String.self, forKey: .summary)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        value = try (try? values.flexibleString(forKey: .value)) ?? values.flexibleBool(forKey: .value).map { $0 ? "1" : "0" }
    }
}

/// A background server task such as a library scan or media analysis.
public struct PlexActivity: Decodable, Sendable, Equatable, Identifiable {
    /// The activity ID, used to cancel it.
    public let uuid: String
    /// Activity type, such as `library.update.section`.
    public let type: String?
    /// Human-readable title.
    public let title: String?
    /// Detail line.
    public let subtitle: String?
    /// Completion percentage, 0–100.
    public let progress: Int?
    /// Whether `cancelActivity(uuid:)` is allowed.
    public let cancellable: Bool
    /// The activity ID.
    public var id: String { uuid }

    enum CodingKeys: String, CodingKey { case uuid, type, title, subtitle, progress, cancellable }

    /// Decodes an activity.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try values.requiredString(forKey: .uuid)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        subtitle = try values.decodeIfPresent(String.self, forKey: .subtitle)
        progress = try values.flexibleInteger(forKey: .progress)
        cancellable = try values.flexibleBool(forKey: .cancellable) ?? false
    }
}

/// A Live TV DVR (tuner + guide pairing).
public struct PlexDVR: Decodable, Sendable, Equatable, Identifiable {
    /// The DVR ID.
    public let key: String
    /// The DVR's unique identifier.
    public let uuid: String?
    /// Display name.
    public let title: String?
    /// The guide lineup it uses.
    public let lineupTitle: String?
    /// The DVR ID.
    public var id: String { key }

    enum CodingKeys: String, CodingKey { case key, uuid, title, lineupTitle }

    /// Decodes a DVR.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.requiredString(forKey: .key)
        uuid = try values.decodeIfPresent(String.self, forKey: .uuid)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        lineupTitle = try values.decodeIfPresent(String.self, forKey: .lineupTitle)
    }
}

extension PlexSetting: PlexListElement { static var plexListKey: String { "Setting" } }
extension PlexActivity: PlexListElement { static var plexListKey: String { "Activity" } }
extension PlexDVR: PlexListElement { static var plexListKey: String { "Dvr" } }

/// Server status, preferences, background activity, library maintenance and Live TV.
/// Most mutations require the server owner or an admin account.
public protocol PlexServerAdministering: Sendable {
    /// The server's name, version and capabilities.
    func serverInfo() async throws -> PlexServerInfo
    /// All server preferences.
    func serverPreferences() async throws -> [PlexSetting]
    /// Background tasks in progress.
    func activities() async throws -> [PlexActivity]
    /// Cancels a background task.
    func cancelActivity(uuid: String) async throws
    /// Scans a section for new files; `force` also refreshes all metadata.
    func scanLibrary(sectionID: String, force: Bool) async throws
    /// Analyzes a section's media (codecs, loudness, thumbnails).
    func analyzeLibrary(sectionID: String) async throws
    /// Permanently removes items whose files are gone.
    func emptyTrash(sectionID: String) async throws
    /// Re-downloads an item's metadata from its agents.
    func refreshMetadata(ratingKey: String) async throws
    /// Deletes an item and its files from the server's disk.
    func deleteItem(ratingKey: String) async throws
    /// Live TV DVRs.
    func dvrs() async throws -> [PlexDVR]
    /// DVR recording rules (subscriptions).
    func recordingRules() async throws -> PlexMediaContainer
    /// Upcoming DVR recordings.
    func scheduledRecordings() async throws -> PlexMediaContainer
    /// A request for the server-sent events stream.
    func notificationsRequest() throws -> URLRequest
}

extension PlexAPIService: PlexServerAdministering {
    /// `GET /`.
    public func serverInfo() async throws -> PlexServerInfo { try await request(PlexEndpoint(.get, "/")) }

    /// `GET /:/prefs`.
    public func serverPreferences() async throws -> [PlexSetting] { try await list(PlexEndpoint(.get, "/:/prefs")) }

    /// `GET /activities`.
    public func activities() async throws -> [PlexActivity] { try await list(PlexEndpoint(.get, "/activities")) }

    /// `DELETE /activities/{uuid}`.
    public func cancelActivity(uuid: String) async throws {
        try await send(PlexEndpoint(.delete, "/activities/\(try PlexURLBuilder.segment(uuid))"))
    }

    /// Scans for new files; `force` also refreshes all metadata.
    public func scanLibrary(sectionID: String, force: Bool = false) async throws {
        try await send(PlexEndpoint(.get, try sectionPath(sectionID) + "/refresh", query: force ? PlexEndpoint.flags("force") : []))
    }

    /// `PUT /library/sections/{id}/analyze`.
    public func analyzeLibrary(sectionID: String) async throws {
        try await send(PlexEndpoint(.put, try sectionPath(sectionID) + "/analyze"))
    }

    /// `PUT /library/sections/{id}/emptyTrash`.
    public func emptyTrash(sectionID: String) async throws {
        try await send(PlexEndpoint(.put, try sectionPath(sectionID) + "/emptyTrash"))
    }

    /// `PUT /library/metadata/{id}/refresh`.
    public func refreshMetadata(ratingKey: String) async throws {
        try await send(PlexEndpoint(.put, "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))/refresh"))
    }

    /// Deletes the item and its media files from the server's disk.
    public func deleteItem(ratingKey: String) async throws {
        try await send(PlexEndpoint(.delete, "/library/metadata/\(try PlexURLBuilder.segment(ratingKey))"))
    }

    /// `GET /livetv/dvrs`.
    public func dvrs() async throws -> [PlexDVR] { try await list(PlexEndpoint(.get, "/livetv/dvrs")) }

    /// `GET /media/subscriptions?includeGrabs=1&includeStorage=1`; rules are returned as raw `Metadata`/`Directory` entries.
    public func recordingRules() async throws -> PlexMediaContainer {
        try await container(PlexEndpoint(.get, "/media/subscriptions", query: PlexEndpoint.flags("includeGrabs", "includeStorage")))
    }

    /// `GET /media/subscriptions/scheduled`.
    public func scheduledRecordings() async throws -> PlexMediaContainer {
        try await container(PlexEndpoint(.get, "/media/subscriptions/scheduled"))
    }

    /// Server-sent events for library, playback and activity changes; consume with `PlexEventSource`.
    public func notificationsRequest() throws -> URLRequest {
        var request = try resourceRequest(path: "/:/eventsource/notifications")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        return request
    }

    private func sectionPath(_ id: String) throws -> String { "/library/sections/\(try PlexURLBuilder.segment(id))" }

    private func list<Element: PlexListElement>(_ endpoint: PlexEndpoint) async throws -> [Element] {
        let envelope: PlexListEnvelope<Element> = try await request(endpoint)
        return envelope.elements
    }
}
