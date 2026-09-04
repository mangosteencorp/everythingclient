// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import Foundation

public struct PopularPerson: Hashable, Codable {
    public let id: Int
    public let name: String
    public let profilePath: String?
    public let knownForDepartment: String?
    public let popularity: Double

    public init(id: Int, name: String, profilePath: String?, knownForDepartment: String?, popularity: Double) {
        self.id = id
        self.name = name
        self.profilePath = profilePath
        self.knownForDepartment = knownForDepartment
        self.popularity = popularity
    }
}
#endif
