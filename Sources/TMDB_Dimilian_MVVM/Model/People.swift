import Foundation
struct People: Codable, Identifiable {
    let id: Int
    let name: String
    var character: String?
    var department: String?
    let profile_path: String?
        
    let known_for_department: String?
    var known_for: [KnownFor]?
    let also_known_as: [String]?
    
    let birthDay: String?
    let deathDay: String?
    let place_of_birth: String?
    
    let biography: String?
    let popularity: Double?
    
    var images: [ImageData]?
    
    struct KnownFor: Codable, Identifiable {
        let id: Int
        let original_title: String?
        let poster_path: String?
    }
}
struct MovieCredits: Decodable {
    let id: Int
    let cast: [People]
    let crew: [People]
}
#if DEBUG
let examplePeoples = [
    People(id: 3416, name: "Demi Moore", character: "Elisabeth", department: nil, profile_path: "/brENIHiNrGUpoBMPqIEQwFNdIsc.jpg", known_for_department: "Acting", known_for: nil, also_known_as: nil, birthDay: nil, deathDay: nil, place_of_birth: nil, biography: nil, popularity: 57.714, images: nil),
    People(id: 6065, name: "Dennis Quaid", character: "Harvey", department: nil, profile_path: "/lMaDAJHzsKH7U3dln2B3kY3rOhE.jpg", known_for_department: "Acting", known_for: nil, also_known_as: nil, birthDay: nil, deathDay: nil, place_of_birth: nil, biography: nil, popularity: 51.034, images: nil),
    People(id: 45849, name: "Christian Erickson", character: "Man at Diner", department: nil, profile_path: "/cpEzQNW1EsRmK8SMj4y5xwevXwM.jpg", known_for_department: "Acting", known_for: nil, also_known_as: nil, birthDay: nil, deathDay: nil, place_of_birth: nil, biography: nil, popularity: 5.673, images: nil),
    People(id: 73995, name: "Céline Vogt", character: "Elisabeth (Young) - Walk of Fame", department: nil, profile_path: "/2pkBIL8OKXXWr1SERPsr7LVAsQX.jpg", known_for_department: "Acting", known_for: nil, also_known_as: nil, birthDay: nil, deathDay: nil, place_of_birth: nil, biography: nil, popularity: 0.882, images: nil),
    People(id: 158124, name: "Shane Sweet", character: "Additional Voices", department: nil, profile_path: "/3fVAoIbfMO2XKtMsIOVpo5fkXVq.jpg", known_for_department: "Acting", known_for: nil, also_known_as: nil, birthDay: nil, deathDay: nil, place_of_birth: nil, biography: nil, popularity: 3.185, images: nil)
]
let exampleMovieCredits = MovieCredits(id: 10, cast: examplePeoples, crew: examplePeoples)
#endif
