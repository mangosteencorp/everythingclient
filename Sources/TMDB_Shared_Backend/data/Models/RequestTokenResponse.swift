import Foundation

struct RequestTokenResponse: Codable {
    let success: Bool
    let requestToken: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case success
        case requestToken = "request_token"
        case expiresAt = "expires_at"
    }
}
