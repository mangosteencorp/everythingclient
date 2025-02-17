import TMDB_Shared_UI
import Foundation
struct TVShowEntity: Equatable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let voteAverage: Float
    let popularity: Float
    let firstAirDate: Date?

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func toTVShowRowEntity() -> MovieRowEntity {
        return MovieRowEntity(id: self.id, posterPath: self.posterPath, title: self.name, voteAverage: Double(self.voteAverage), releaseDate: self.firstAirDate, overview: self.overview)
    }
}

