import Foundation

/// Builds the backend's `Decodable` models from inline JSON.
///
/// The models are decode-only and have no memberwise initialiser to reach from a test target, so
/// the payload that TMDB would return is the cheapest way to get a realistic value.
public enum JSONFixture {
    public static func decode<T: Decodable>(_ type: T.Type = T.self, from json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }
}
