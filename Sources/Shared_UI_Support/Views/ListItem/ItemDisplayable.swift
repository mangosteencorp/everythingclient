// Shared across platforms
public protocol ItemDisplayable {
    func getId() -> String?
    func getTitle() -> String
    func getDescription() -> String
    func getReleaseDate() -> String?
    func getRating() -> Float?
    func getImageURL() -> String?
    func isFavorited() -> Bool
    func setFavorited(_ favorited: Bool)
}
