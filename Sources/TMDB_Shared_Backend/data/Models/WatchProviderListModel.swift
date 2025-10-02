import Foundation

public struct WatchProviderListModel: Codable {
    public let results: [WatchProviderModel]
}

public struct WatchProviderModel: Codable {
    public let displayPriority: Int
    public let logoPath: String
    public let providerName: String
    public let providerId: Int

    enum CodingKeys: String, CodingKey {
        case displayPriority = "display_priority"
        case logoPath = "logo_path"
        case providerName = "provider_name"
        case providerId = "provider_id"
    }
}