import Foundation

public struct TVListResultModel: Codable {
    let dates: Dates
    let page: Int
    public let results: [APITVShow]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case dates, page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct Dates: Codable {
    let maximum: String
    let minimum: String
}
