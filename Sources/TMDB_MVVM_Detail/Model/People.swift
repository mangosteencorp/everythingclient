import Foundation

struct People: Codable, Identifiable {
    let id: Int
    let name: String
    var character: String?
    var department: String?
    let profilePath: String?
    let knownForDepartment: String?
    var knownFor: [KnownFor]?
    let alsoKnownAs: [String]?
    let birthDay: String?
    let deathDay: String?
    let placeOfBirth: String?
    let biography: String?
    let popularity: Double?
    var images: [ImageData]?

    private enum CodingKeys: String, CodingKey {
        case id, name, character, department
        case profilePath
        case knownForDepartment
        case knownFor
        case alsoKnownAs
        case birthDay, deathDay
        case placeOfBirth
        case biography, popularity, images
    }

    struct KnownFor: Codable, Identifiable {
        let id: Int
        let originalTitle: String?
        let posterPath: String?

        private enum CodingKeys: String, CodingKey {
            case id
            case originalTitle = "original_title"
            case posterPath = "poster_path"
        }
    }

    static func redacted() -> People {
        return People(
            id: Int.random(in: 1 ... 100_000),
            name: "",
            profilePath: nil,
            knownForDepartment: "Acting",
            alsoKnownAs: nil,
            birthDay: nil,
            deathDay: nil,
            placeOfBirth: nil,
            biography: nil,
            popularity: 57.714
        )
    }
}

struct MovieCredits: Decodable {
    let id: Int
    let cast: [People]
    let crew: [People]
}

//swiftlint:disable all
#if DEBUG
let examplePeoples = [
    People(
        id: 3416,
        name: "Demi Moore",
        character: "Elisabeth",
        department: nil,
        profilePath: "/brENIHiNrGUpoBMPqIEQwFNdIsc.jpg",
        knownForDepartment: "Acting",
        knownFor: nil,
        alsoKnownAs: nil,
        birthDay: nil,
        deathDay: nil,
        placeOfBirth: nil,
        biography: nil,
        popularity: 57.714,
        images: nil
    ),
    People(
        id: 6065,
        name: "Dennis Quaid",
        character: "Harvey",
        department: nil,
        profilePath: "/lMaDAJHzsKH7U3dln2B3kY3rOhE.jpg",
        knownForDepartment: "Acting",
        knownFor: nil,
        alsoKnownAs: nil,
        birthDay: nil,
        deathDay: nil,
        placeOfBirth: nil,
        biography: nil,
        popularity: 51.034,
        images: nil
    ),
    People(
        id: 45849,
        name: "Christian Erickson",
        character: "Man at Diner",
        department: nil,
        profilePath: "/cpEzQNW1EsRmK8SMj4y5xwevXwM.jpg",
        knownForDepartment: "Acting",
        knownFor: nil,
        alsoKnownAs: nil,
        birthDay: nil,
        deathDay: nil,
        placeOfBirth: nil,
        biography: nil,
        popularity: 5.673,
        images: nil
    ),
    People(
        id: 73995,
        name: "Céline Vogt",
        character: "Elisabeth (Young) - Walk of Fame",
        department: nil,
        profilePath: "/2pkBIL8OKXXWr1SERPsr7LVAsQX.jpg",
        knownForDepartment: "Acting",
        knownFor: nil,
        alsoKnownAs: nil,
        birthDay: nil,
        deathDay: nil,
        placeOfBirth: nil,
        biography: nil,
        popularity: 0.882,
        images: nil
    ),
    People(
        id: 158_124,
        name: "Shane Sweet",
        character: "Additional Voices",
        department: nil,
        profilePath: "/3fVAoIbfMO2XKtMsIOVpo5fkXVq.jpg",
        knownForDepartment: "Acting",
        knownFor: nil,
        alsoKnownAs: nil,
        birthDay: nil,
        deathDay: nil,
        placeOfBirth: nil,
        biography: nil,
        popularity: 3.185,
        images: nil
    ),
]
let exampleMovieCredits = MovieCredits(id: 10, cast: examplePeoples, crew: examplePeoples)
#endif
//swiftlint:enable all
