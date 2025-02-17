import Foundation
// swiftlint:disable identifier_name
public struct APITVShow: Codable {
    let id: Int
    let name: String
    let overview: String
    let poster_path: String?
    let vote_average: Float
    let popularity: Float
    let first_air_date: String?
} 
// swiftlint:enable identifier_name
