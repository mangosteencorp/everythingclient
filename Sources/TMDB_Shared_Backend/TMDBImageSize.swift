import Foundation

public enum TMDBImageSize {
    // Poster sizes (for movie/TV show posters)
    case posterTiny
    case posterSmall
    case posterMedium
    case posterLarge
    case posterExtraLarge

    // Profile/Cast sizes (for person images)
    case profileSmall
    case profileMedium
    case profileLarge

    // Backdrop sizes (for background/hero images)
    case backdropSmall
    case backdropMedium
    case backdropLarge

    // Logo sizes
    case logoTiny
    case logoSmall
    case logoMedium
    case logoLarge
    case logoExtraLarge
    case logoExtraExtraLarge

    // Still sizes (for episode/scene stills)
    case stillSmall
    case stillMedium
    case stillLarge

    case original

    private static let baseURL = "https://image.tmdb.org/t/p"

    private var sizeString: String {
        switch self {
        case .posterTiny: return "w92"
        case .posterSmall: return "w154"
        case .posterMedium: return "w342"
        case .posterLarge: return "w500"
        case .posterExtraLarge: return "w780"
        case .profileSmall: return "w45"
        case .profileMedium: return "w185"
        case .profileLarge: return "h632"
        case .backdropSmall: return "w300"
        case .backdropMedium: return "w780"
        case .backdropLarge: return "w1280"
        case .logoTiny: return "w45"
        case .logoSmall: return "w92"
        case .logoMedium: return "w154"
        case .logoLarge: return "w185"
        case .logoExtraLarge: return "w300"
        case .logoExtraExtraLarge: return "w500"
        case .stillSmall: return "w92"
        case .stillMedium: return "w185"
        case .stillLarge: return "w300"
        case .original: return "original"
        }
    }

    public func buildImageUrl(path: String) -> URL? {
        guard !path.isEmpty else { return nil }
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: "\(Self.baseURL)/\(sizeString)\(cleanPath)")
    }
}
