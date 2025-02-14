import Foundation
// swiftlint:disable identifier_name
public struct MovieCreditsModel: Codable {
    public let id: Int
    public let cast: [CastMember]
    public let crew: [CrewMember]
}

public struct CastMember: Codable {
    public let adult: Bool
    public let gender: Int?
    public let id: Int
    public let known_for_department: String
    public let name: String
    public let original_name: String
    public let popularity: Double
    public let profile_path: String?
    public let cast_id: Int
    public let character: String
    public let credit_id: String
    public let order: Int
}

public struct CrewMember: Codable {
    public let adult: Bool
    public let gender: Int?
    public let id: Int
    public let known_for_department: String
    public let name: String
    public let original_name: String
    public let popularity: Double
    public let profile_path: String?
    public let credit_id: String
    public let department: String
    public let job: String
}

// swiftlint:enable identifier_name