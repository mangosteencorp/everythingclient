// Entities
import Foundation
struct Movie {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let voteAverage: Float
    let popularity: Float
    let releaseDate: Date?
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
extension Movie: Equatable {}
