import Foundation

/// Home and discovery shelves. Load a hub's full list with `container(key: hub.key)`.
public protocol PlexHubServing: Sendable {
    /// Home screen shelves such as Recently Added, with up to `count` items each.
    func homeHubs(count: Int) async throws -> [PlexHub]
    /// In-progress items and next episodes, one entry per show.
    func continueWatching(count: Int) async throws -> [PlexMetadata]
    /// A library section's recommendation shelves.
    func sectionHubs(sectionID: String, count: Int) async throws -> [PlexHub]
    /// Shelves related to an item: similar titles, its collections, more from its cast.
    func relatedHubs(ratingKey: String, count: Int) async throws -> [PlexHub]
}

extension PlexAPIService: PlexHubServing {
    /// Recently added, recommended and other home shelves. Empty shelves are dropped.
    public func homeHubs(count: Int = 12) async throws -> [PlexHub] {
        try await hubs(PlexEndpoint(.get, "/hubs", query: hubQuery(count)))
    }

    /// Continue Watching merged with On Deck, like Plex Web: one entry per show, preferring an in-progress episode.
    public func continueWatching(count: Int = 20) async throws -> [PlexMetadata] {
        let query = hubQuery(count) + [URLQueryItem(name: "identifier", value: "home.continue,home.ondeck")]
        var result: [PlexMetadata] = []
        for item in try await hubs(PlexEndpoint(.get, "/hubs", query: query)).flatMap(\.metadata) {
            guard item.type == "episode", let show = item.grandparentRatingKey,
                  let index = result.firstIndex(where: { $0.type == "episode" && $0.grandparentRatingKey == show })
            else {
                if !result.contains(where: { $0.ratingKey == item.ratingKey }) { result.append(item) }
                continue
            }
            if result[index].viewOffset == nil, item.viewOffset != nil { result[index] = item }
        }
        return result
    }

    /// `GET /hubs/sections/{id}?count=…`. Empty shelves are dropped.
    public func sectionHubs(sectionID: String, count: Int = 12) async throws -> [PlexHub] {
        try await hubs(PlexEndpoint(.get, "/hubs/sections/\(try PlexURLBuilder.segment(sectionID))", query: hubQuery(count)))
    }

    /// "More like this", collections containing the item, and other people's work.
    public func relatedHubs(ratingKey: String, count: Int = 10) async throws -> [PlexHub] {
        let path = "/hubs/metadata/\(try PlexURLBuilder.segment(ratingKey))/related"
        return try await hubs(PlexEndpoint(.get, path, query: [URLQueryItem(name: "count", value: String(count))]))
    }

    private func hubQuery(_ count: Int) -> [URLQueryItem] {
        [URLQueryItem(name: "count", value: String(count))] + PlexEndpoint.flags("includeGuids")
    }

    private func hubs(_ endpoint: PlexEndpoint) async throws -> [PlexHub] {
        try await container(endpoint).hubs.filter { !$0.metadata.isEmpty }
    }
}
