import Foundation

struct People: Codable, Identifiable {
    let id: Int
    let name: String
    var character: String?
    var department: String?
    let profilePath: String?
    let knownForDepartment: String?
    let popularity: Double?

    private enum CodingKeys: String, CodingKey {
        case id, name, character, department
        case profilePath = "profile_path"
        case knownForDepartment = "known_for_department"
        case popularity
    }

    static func redacted() -> People {
        return People(
            id: Int.random(in: 1 ... 100_000),
            name: "",
            character: nil,
            department: nil,
            profilePath: nil,
            knownForDepartment: "Acting",
            popularity: 57.714
        )
    }
}

struct MovieCredits: Decodable {
    let id: Int
    let cast: [People]
    let crew: [People]
}

// swiftlint:disable all
#if DEBUG
let examplePeoples = [
    People(
        id: 3416,
        name: "Demi Moore",
        character: "Elisabeth",
        department: nil,
        profilePath: "/brENIHiNrGUpoBMPqIEQwFNdIsc.jpg",
        knownForDepartment: "Acting",
        popularity: 57.714
    ),
    People(
        id: 6065,
        name: "Dennis Quaid",
        character: "Harvey",
        department: nil,
        profilePath: "/lMaDAJHzsKH7U3dln2B3kY3rOhE.jpg",
        knownForDepartment: "Acting",
        popularity: 51.034
    ),
    People(
        id: 45849,
        name: "Christian Erickson",
        character: "Man at Diner",
        department: nil,
        profilePath: "/cpEzQNW1EsRmK8SMj4y5xwevXwM.jpg",
        knownForDepartment: "Acting",
        popularity: 5.673
    ),
    People(
        id: 73995,
        name: "Céline Vogt",
        character: "Elisabeth (Young) - Walk of Fame",
        department: nil,
        profilePath: "/2pkBIL8OKXXWr1SERPsr7LVAsQX.jpg",
        knownForDepartment: "Acting",
        popularity: 0.882
    ),
    People(
        id: 158_124,
        name: "Shane Sweet",
        character: "Additional Voices",
        department: nil,
        profilePath: "/3fVAoIbfMO2XKtMsIOVpo5fkXVq.jpg",
        knownForDepartment: "Acting",
        popularity: 3.185
    ),
]
let exampleMovieCredits = MovieCredits(id: 10, cast: examplePeoples, crew: examplePeoples)
#endif
// swiftlint:enable all
