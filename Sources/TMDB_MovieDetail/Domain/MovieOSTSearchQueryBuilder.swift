import Foundation

public enum MovieOSTSearchQueryBuilder {
    public static func searchTerm(for movieTitle: String) -> String {
        let trimmed = movieTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "soundtrack"
        }
        return "\(trimmed) soundtrack"
    }

    public static func isLikelySoundtrackAlbum(title: String) -> Bool {
        let normalized = title.lowercased()
        return normalized.contains("soundtrack")
            || normalized.contains("ost")
            || normalized.contains("original motion picture")
    }
}
