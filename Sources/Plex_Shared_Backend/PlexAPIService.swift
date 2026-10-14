import Foundation

public protocol PlexLibraryServing: Sendable {
    func libraries() async throws -> [PlexLibrary]
    func items(sectionID: String, page: PlexPagination?) async throws -> PlexMediaContainer
    func metadata(ratingKey: String) async throws -> PlexMetadata
    func children(ratingKey: String, page: PlexPagination?) async throws -> PlexMediaContainer
    func grandchildren(ratingKey: String, page: PlexPagination?) async throws -> PlexMediaContainer
    func downloadPlan(ratingKey: String, mediaIndex: Int, selection: PlexDownloadPartSelection) async throws -> PlexDownloadPlan
}

/// Server-scoped service analogous to TMDBAPIService; transport and feature-facing APIs are mockable.
public struct PlexAPIService: PlexLibraryServing {
    private let configuration: PlexServerConfiguration
    private let executor: PlexRequestExecutor

    public init(configuration: PlexServerConfiguration, transport: any PlexHTTPTransport = PlexURLSessionTransport()) {
        self.configuration = configuration
        executor = PlexRequestExecutor(transport: transport)
    }

    public func request<Response: Decodable & Sendable>(_ endpoint: PlexEndpoint) async throws -> Response {
        try await executor.decode(Response.self, request: endpoint.makeRequest(configuration: configuration))
    }

    /// Standard library sections. Shared pseudo-libraries from /media/providers are not discovered.
    /// Call items(sectionID: "shared") when a caller already knows it has shared items.
    public func libraries() async throws -> [PlexLibrary] {
        let response: PlexResponse = try await request(.libraries)
        return response.mediaContainer.libraries
    }

    public func items(sectionID: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        let response: PlexResponse = try await request(.libraryItems(sectionID: sectionID, page: page))
        return response.mediaContainer
    }

    public func metadata(ratingKey: String) async throws -> PlexMetadata {
        let response: PlexResponse = try await request(.metadata(ratingKey: ratingKey))
        guard let item = response.mediaContainer.metadata.first(where: { $0.ratingKey == ratingKey }) else {
            throw PlexAPIError.metadataNotFound
        }
        return item
    }

    public func children(ratingKey: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        let response: PlexResponse = try await request(.children(ratingKey: ratingKey, page: page))
        return response.mediaContainer
    }

    /// Plezy uses /grandchildren for playable show/season descendants because /allLeaves can be empty for seasons.
    public func grandchildren(ratingKey: String, page: PlexPagination? = nil) async throws -> PlexMediaContainer {
        let response: PlexResponse = try await request(.grandchildren(ratingKey: ratingKey, page: page))
        return response.mediaContainer
    }

    public func downloadPlan(
        ratingKey: String, mediaIndex: Int = 0, selection: PlexDownloadPartSelection = .allParts
    ) async throws -> PlexDownloadPlan {
        let item = try await metadata(ratingKey: ratingKey)
        return try PlexDownloadPlanner(configuration: configuration).plan(for: item, mediaIndex: mediaIndex, selection: selection)
    }
}
