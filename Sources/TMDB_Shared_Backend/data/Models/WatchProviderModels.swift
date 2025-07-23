import Foundation

public struct WatchProviderResponse: Codable {
    public let id: Int
    public let results: [String: WatchProviderRegion]
    
    private enum CodingKeys: String, CodingKey {
        case id, results
    }
}

public struct WatchProviderRegion: Codable {
    public let link: String
    public let buy: [WatchProvider]?
    public let rent: [WatchProvider]?
    public let flatrate: [WatchProvider]?
    public let free: [WatchProvider]?
    public let ads: [WatchProvider]?
    
    private enum CodingKeys: String, CodingKey {
        case link, buy, rent, flatrate, free, ads
    }
}

public struct WatchProvider: Codable, Identifiable {
    public let id: Int
    public let logoPath: String?
    public let providerName: String
    public let displayPriority: Int
    
    private enum CodingKeys: String, CodingKey {
        case id = "provider_id"
        case logoPath = "logo_path"
        case providerName = "provider_name"
        case displayPriority = "display_priority"
    }
    
    public var logoURL: String? {
        guard let logoPath = logoPath else { return nil }
        return "https://image.tmdb.org/t/p/original\(logoPath)"
    }
} 