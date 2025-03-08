import Foundation

struct ImageData: Codable, Identifiable {
    var id: String {
        filePath
    }

    let aspectRatio: Float
    let filePath: String
    let height: Int
    let width: Int

    private enum CodingKeys: String, CodingKey {
        case aspectRatio = "aspect_ratio"
        case filePath = "file_path"
        case height
        case width
    }
}
