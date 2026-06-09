import Foundation

struct PersonDetail: Decodable {
    let adult: Bool?
    let alsoKnownAs: [String]
    let biography: String
    let birthday: String?
    let deathday: String?
    let gender: Int?
    let homepage: String?
    let id: Int
    let imdbId: String?
    let knownForDepartment: String?
    let name: String
    let placeOfBirth: String?
    let popularity: Double
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case adult, biography, birthday, deathday, gender, homepage, id, name, popularity
        case alsoKnownAs = "also_known_as"
        case imdbId = "imdb_id"
        case knownForDepartment = "known_for_department"
        case placeOfBirth = "place_of_birth"
        case profilePath = "profile_path"
    }
}

struct PersonMovieCredits: Decodable {
    let id: Int
    let cast: [PersonMovieCredit]
    let crew: [PersonMovieCredit]
}

struct PersonMovieCredit: Decodable, Identifiable {
    let adult: Bool?
    let backdropPath: String?
    let character: String?
    let creditId: String
    let department: String?
    let id: Int
    let job: String?
    let order: Int?
    let originalTitle: String?
    let overview: String
    let popularity: Double
    let posterPath: String?
    let releaseDate: String?
    let title: String
    let voteAverage: Double
    let voteCount: Int

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

extension PersonDetail {
    var lifespan: String? {
        switch (birthday, deathday) {
        case let (birthday?, deathday?):
            return "\(birthday) - \(deathday)"
        case let (birthday?, nil):
            return "Born \(birthday)"
        default:
            return nil
        }
    }
}

extension PersonMovieCredits {
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

extension PersonMovieCredit {
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
