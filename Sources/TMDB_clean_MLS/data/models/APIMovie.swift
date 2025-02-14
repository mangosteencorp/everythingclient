// API Models
import SwiftUI

//swiftlint:disable identifier_name
public struct APIMovie: Codable {
    let id: Int
    let title: String
    let overview: String
    let poster_path: String?
    let vote_average: Float
    let popularity: Float
    let release_date: String?
}

//swiftlint:enable identifier_name
