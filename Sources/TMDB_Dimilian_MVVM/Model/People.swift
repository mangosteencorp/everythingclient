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
