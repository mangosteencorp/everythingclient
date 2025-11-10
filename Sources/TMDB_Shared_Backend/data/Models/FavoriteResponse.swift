import Foundation

public struct FavoriteResponse: Codable {
    public let success: Bool
    public let statusCode: Int
    public let statusMessage: String

    private enum CodingKeys: String, CodingKey {
        case success
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}