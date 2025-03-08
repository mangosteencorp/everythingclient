// API Models
import SwiftUI

// swiftlint:disable identifier_name
public struct APIMovie: Codable { // TODO: changing name to TVShow
    let id: Int
    let title: String
    let overview: String
    let poster_path: String?
    let vote_average: Float
    let popularity: Float
    let release_date: String?
    enum CodingKeys: String, CodingKey {
        case id
        case title = "name" // TV show
        case overview
        case poster_path = "poster_path"
        case vote_average = "vote_average"
        case popularity
        case release_date = "first_air_date" // TV show
    }
}

// swiftlint:enable identifier_name
