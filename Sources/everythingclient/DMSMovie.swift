import Foundation

struct Keyword: Codable, Identifiable {
    let id: Int
    let name: String
}


struct ImageData: Codable, Identifiable {
    var id: String {
        file_path
    }
    let aspect_ratio: Float
    let file_path: String
    let height: Int
    let width: Int
}

struct Genre: Codable, Identifiable {
    let id: Int
    let name: String
}

public struct Movie: Codable, Identifiable {
    public let id: Int
    
    let original_title: String
    let title: String
    var userTitle: String {
        return original_title //: title
    }
    
    let overview: String
    let poster_path: String?
    let backdrop_path: String?
    let popularity: Float
    let vote_average: Float
    let vote_count: Int
    
    let release_date: String?
    var releaseDate: Date? {
        return release_date != nil ? Movie.dateFormatter.date(from: release_date!) : Date()
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd"
        return formatter
    }()
    
    let genres: [Genre]?
    let runtime: Int?
    let status: String?
    let video: Bool
    
    var keywords: Keywords?
    var images: MovieImages?
    
    var production_countries: [productionCountry]?
    
    var character: String?
    var department: String?
    
    struct Keywords: Codable {
        let keywords: [Keyword]?
    }
    
    struct MovieImages: Codable {
        let posters: [ImageData]?
        let backdrops: [ImageData]?
    }
    
    struct productionCountry: Codable, Identifiable {
        var id: String {
            name
        }
        let name: String
    }
}

let sampleEmptyMovie = Movie(id: 0,
                        original_title: "Test movie Test movie Test movie Test movie Test movie Test movie Test movie ",
                        title: "Test movie Test movie Test movie Test movie Test movie Test movie Test movie  Test movie Test movie Test movie",
                        overview: "Test desc",
                        poster_path: "/uC6TTUhPpQCmgldGyYveKRAu8JN.jpg",
                        backdrop_path: "/nl79FQ8xWZkhL3rDr1v2RFFR6J0.jpg",
                        popularity: 50.5,
                        vote_average: 8.9,
                        vote_count: 1000,
                        release_date: "1972-03-14",
                        genres: [Genre(id: 0, name: "test")],
                        runtime: 80,
                        status: "released",
                        video: false)

let sampleApeMovie = Movie(
    id: 653346,
    original_title: "Kingdom of the Planet of the Apes",
    title: "Kingdom of the Planet of the Apes",
    overview: "Several generations in the future following Caesar's reign, apes are now the dominant species and live harmoniously while humans have been reduced to living in the shadows. As a new tyrannical ape leader builds his empire, one young ape undertakes a harrowing journey that will cause him to question all that he has known about the past and to make choices that will define a future for apes and humans alike.",
    poster_path: "/gKkl37BQuKTanygYQG1pyYgLVgf.jpg",
    backdrop_path: "/fqv8v6AycXKsivp1T5yKtLbGXce.jpg",
    popularity: 4050.674,
    vote_average: 6.861,
    vote_count: 955,
    release_date: "2024-05-10",
    genres: nil,
    runtime: nil,
    status: nil,
    video: false,
    keywords: nil,
    images: nil,
    production_countries: nil,
    character: nil,
    department: nil
)
