// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import Foundation
public enum TVShowFeedType: Hashable, Codable {
    case airingToday
    case onTheAir
    case discover
    case discoverWithGenre(Genre)  // For movie genres
    case discoverWithTVGenre(Genre)  // For TV genres
    case discoverWithCast(PopularPerson)

    var title: String {
        switch self {
        case .airingToday:
            return "Airing Today"
        case .onTheAir:
            return "On the air"
        case .discover:
            return "Discover Movies"
        case .discoverWithGenre(let genre):
            return "\(genre.name) Movies"
        case .discoverWithTVGenre(let genre):
            return "\(genre.name) TV Shows"
        case .discoverWithCast(let person):
            return "\(person.name) Movies"
        }
    }

    var iconName: String {
        switch self {
        case .airingToday:
            return "play.circle"
        case .onTheAir:
            return "calendar"
        case .discover:
            return "magnifyingglass"
        case .discoverWithGenre, .discoverWithTVGenre:
            return "tag"
        case .discoverWithCast:
            return "person"
        }
    }
}
#endif
