import Foundation

public struct PersonDetail: Decodable {
    public let adult: Bool?
    public let alsoKnownAs: [String]
    public let biography: String
    public let birthday: String?
    public let deathday: String?
    public let gender: Int?
    public let homepage: String?
    public let id: Int
    public let imdbId: String?
    public let knownForDepartment: String?
    public let name: String
    public let placeOfBirth: String?
    public let popularity: Double
    public let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case adult, biography, birthday, deathday, gender, homepage, id, name, popularity
        case alsoKnownAs = "also_known_as"
        case imdbId = "imdb_id"
        case knownForDepartment = "known_for_department"
        case placeOfBirth = "place_of_birth"
        case profilePath = "profile_path"
    }
}

public struct PersonMovieCredits: Decodable {
    public let id: Int
    public let cast: [PersonMovieCredit]
    public let crew: [PersonMovieCredit]
}

public struct PersonMovieCredit: Decodable, Identifiable {
    public let adult: Bool?
    public let backdropPath: String?
    public let character: String?
    public let creditId: String
    public let department: String?
    public let id: Int
    public let job: String?
    public let order: Int?
    public let originalTitle: String?
    public let overview: String
    public let popularity: Double
    public let posterPath: String?
    public let releaseDate: String?
    public let title: String
    public let voteAverage: Double
    public let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case adult, character, department, id, job, order, overview, popularity, title
        case backdropPath = "backdrop_path"
        case creditId = "credit_id"
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}

public extension PersonMovieCredits {
    var featuredCredits: [PersonMovieCredit] {
        let uniqueCredits = Dictionary(grouping: cast + crew, by: \.id)
            .compactMap { _, credits in
                credits.max { lhs, rhs in
                    lhs.sortScore < rhs.sortScore
                }
            }

        return uniqueCredits
            .sorted { lhs, rhs in
                if lhs.releaseYear == rhs.releaseYear {
                    return lhs.popularity > rhs.popularity
                }
                return lhs.releaseYear > rhs.releaseYear
            }
    }
}

public extension PersonMovieCredit {
    var roleText: String? {
        if let character, !character.isEmpty {
            return character
        }
        if let job, !job.isEmpty {
            return job
        }
        return department
    }

    var releaseYearText: String? {
        guard releaseYear > 0 else { return nil }
        return String(releaseYear)
    }

    fileprivate var releaseYear: Int {
        guard let releaseDate else { return 0 }
        return Int(releaseDate.prefix(4)) ?? 0
    }

    fileprivate var sortScore: Double {
        let orderBoost = order.map { max(0, 20 - $0) } ?? 0
        return popularity + Double(orderBoost)
    }
}
