import Foundation
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
    
    public struct Keywords: Codable {
        let keywords: [Keyword]?
    }
    
    public struct MovieImages: Codable {
        let posters: [ImageData]?
        let backdrops: [ImageData]?
    }
    
    public struct productionCountry: Codable, Identifiable {
        public var id: String {
            name
        }
        let name: String
    }
    
    static func placeholder(id: Int) -> Movie {
        return Movie(id: id, original_title: "", title: "", overview: "", poster_path: nil, backdrop_path: nil, popularity: 0.0, vote_average: 0.0, vote_count: 0, release_date: nil, genres: nil, runtime: nil, status: nil, video: false)
    }
    public init(id: Int, original_title: String, title: String, overview: String, poster_path: String?, backdrop_path: String?, popularity: Float, vote_average: Float, vote_count: Int, release_date: String?, genres: [Genre]?, runtime: Int?, status: String?, video: Bool, keywords: Keywords? = nil, images: MovieImages? = nil, production_countries: [productionCountry]? = nil, character: String? = nil, department: String? = nil) {
        self.id = id
        self.original_title = original_title
        self.title = title
        self.overview = overview
        self.poster_path = poster_path
        self.backdrop_path = backdrop_path
        self.popularity = popularity
        self.vote_average = vote_average
        self.vote_count = vote_count
        self.release_date = release_date
        self.genres = genres
        self.runtime = runtime
        self.status = status
        self.video = video
        self.keywords = keywords
        self.images = images
        self.production_countries = production_countries
        self.character = character
        self.department = department
    }
}
