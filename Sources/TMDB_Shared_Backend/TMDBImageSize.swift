import Foundation

public enum TMDBImageSize {
    // Poster sizes (for movie/TV show posters)
    case posterTiny           // w92
    case posterSmall          // w154
    case posterMedium         // w342
    case posterLarge          // w500
    case posterExtraLarge     // w780

    // Profile/Cast sizes (for person images)
    case profileSmall         // w45
    case profileMedium        // w185
    case profileLarge         // h632

    // Backdrop sizes (for background/hero images)
    case backdropSmall        // w300
    case backdropMedium       // w780
    case backdropLarge        // w1280

    // Logo sizes
    case logoTiny             // w45
    case logoSmall            // w92
    case logoMedium           // w154
    case logoLarge            // w185
    case logoExtraLarge       // w300
    case logoExtraExtraLarge  // w500

    // Still sizes (for episode/scene stills)
    case stillSmall           // w92
    case stillMedium          // w185
    case stillLarge           // w300

    // Original (full resolution)
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

    /// Builds a complete TMDB image URL from a path
    /// - Parameter path: The image path from TMDB API (e.g., "/abc123.jpg")
    /// - Returns: Complete URL, or nil if path is empty
    public func buildImageUrl(path: String) -> URL? {
        guard !path.isEmpty else { return nil }
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: "\(Self.baseURL)/\(sizeString)\(cleanPath)")
    }
}
