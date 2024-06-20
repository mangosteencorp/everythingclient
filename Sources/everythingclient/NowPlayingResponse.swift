import Foundation

public struct NowPlayingResponse: Decodable {
    let dates: Dates
    let page: Int
    public let results: [Movie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case dates, page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct Dates: Decodable {
    let maximum: String
    let minimum: String
}

