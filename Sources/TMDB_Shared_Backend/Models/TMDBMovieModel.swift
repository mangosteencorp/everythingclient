
// API Models
import SwiftUI
public struct TMDBMovieModel: Codable {
    let id: Int
    let title: String
    let overview: String
    let poster_path: String?
    let vote_average: Float
    let popularity: Float
    let release_date: String?
}
