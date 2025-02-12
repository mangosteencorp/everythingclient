// swiftlint:disable identifier_name
public struct AccountInfoModel: Codable {
    public let avatar: Avatar
    public let id: Int
    public let iso_639_1: String
    public let iso_3166_1: String
    public let name: String
    public let include_adult: Bool
    public let username: String

    public struct Avatar: Codable {
        public let gravatar: Gravatar
        public let tmdb: TMDB

        public struct Gravatar: Codable {
            public let hash: String
        }

        public struct TMDB: Codable {
            public let avatar_path: String?
        }
    }
}
// swiftlint:enable identifier_name