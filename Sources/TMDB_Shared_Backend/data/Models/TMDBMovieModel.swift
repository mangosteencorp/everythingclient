// API Models
import SwiftUI

// swiftlint:disable identifier_name
public struct TMDBMovieModel: Codable {
    public let id: Int
    public let title: String
    public let overview: String
    public let poster_path: String?
    public let vote_average: Float
    public let popularity: Float?
    public let release_date: String?
    public let genre_ids: [Int]?
}

// swiftlint:enable identifier_name
