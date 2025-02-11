import Foundation
import TMDB_Shared_UI
public struct Genre: Codable, Identifiable {
    public let id: Int
    let name: String
}

public struct Movie: Codable, Identifiable {
    public let id: Int
    
    public let originalTitle: String
    public let title: String
    public var userTitle: String {
        return originalTitle
    }
    
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let popularity: Float
    public let voteAverage: Float
    public let voteCount: Int
    
    public let releaseDate: String?
    public var releaseDateFormatted: Date? {
        return releaseDate != nil ? Movie.dateFormatter.date(from: releaseDate!) : Date()
    }
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    public let genres: [Genre]?
    public let video: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id
        case originalTitle = "original_title"
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case popularity
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case releaseDate = "release_date"
        case genres
        case video
    }
    
    public func toMovieRowEntity() -> MovieRowEntity {
        return MovieRowEntity(
            id: id,
            posterPath: posterPath,
            title: userTitle,
            voteAverage: Double(voteAverage),
            releaseDate: releaseDateFormatted,
            overview: overview
        )
    }
}
#if DEBUG
// swiftlint:disable all
let sampleEmptyMovie = Movie(id: 0,
                        originalTitle: "Test movie Test movie Test movie Test movie Test movie Test movie Test movie ",
                        title: "Test movie Test movie Test movie Test movie Test movie Test movie Test movie  Test movie Test movie Test movie",
                        overview: "Test desc",
                        posterPath: "/uC6TTUhPpQCmgldGyYveKRAu8JN.jpg",
                        backdropPath: "/nl79FQ8xWZkhL3rDr1v2RFFR6J0.jpg",
                        popularity: 50.5,
                        voteAverage: 8.9,
                        voteCount: 1000,
                        releaseDate: "1972-03-14",
                        genres: [Genre(id: 0, name: "test")],
                        video: false)

let sampleApeMovie = Movie(
    id: 653346,
    originalTitle: "Kingdom of the Planet of the Apes",
    title: "Kingdom of the Planet of the Apes",
    overview: "Several generations in the future following Caesar's reign, apes are now the dominant species and live harmoniously while humans have been reduced to living in the shadows. As a new tyrannical ape leader builds his empire, one young ape undertakes a harrowing journey that will cause him to question all that he has known about the past and to make choices that will define a future for apes and humans alike.",
    posterPath: "/gKkl37BQuKTanygYQG1pyYgLVgf.jpg",
    backdropPath: "/fqv8v6AycXKsivp1T5yKtLbGXce.jpg",
    popularity: 4050.674,
    voteAverage: 6.861,
    voteCount: 955,
    releaseDate: "2024-05-10",
    genres: nil,
    video: false
)
// swiftlint:enable all
#endif