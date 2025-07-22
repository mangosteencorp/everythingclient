import Foundation

public struct PopularPerson {
    public let id: Int
    public let name: String
    public let profilePath: String?
    public let knownForDepartment: String
    public let popularity: Double
    
    public init(id: Int, name: String, profilePath: String?, knownForDepartment: String, popularity: Double) {
        self.id = id
        self.name = name
        self.profilePath = profilePath
        self.knownForDepartment = knownForDepartment
        self.popularity = popularity
    }
}