import Foundation

/// Finds a movie's episode in a review show whose episodes are titled "<Movie Title> Review", like IGN Movie Reviews.
public enum PodcastReviewMatcher {
    /// The episode reviewing `movieTitle`, or nil.
    ///
    /// Titles must be equal once a trailing "Review" is dropped, ignoring case, accents, punctuation and "&" versus
    /// "and", so "Superman & Lois Season 4 Review" never passes for "Superman". When the show reviewed two films
    /// of the same title, the episode published closest to `releaseDate` wins, or the newest one without it.
    public static func review(
        of movieTitle: String,
        releasedOn releaseDate: Date? = nil,
        in episodes: [PodcastEpisode]
    ) -> PodcastEpisode? {
        let title = normalized(movieTitle)
        guard !title.isEmpty else { return nil }
        let matches = episodes.filter { reviewedTitle(of: $0.title) == title }
        guard let releaseDate else {
            return matches.max { ($0.publishedAt ?? .distantPast) < ($1.publishedAt ?? .distantPast) }
        }
        return matches.min { distance($0, from: releaseDate) < distance($1, from: releaseDate) }
    }

    /// "Superman & Lois: Review" → "superman and lois".
    static func reviewedTitle(of episodeTitle: String) -> String {
        let title = normalized(episodeTitle)
        let suffix = " review"
        return title.hasSuffix(suffix) ? String(title.dropLast(suffix.count)) : title
    }

    /// Lowercased, accents and punctuation removed, "&" spelled out, words single-spaced.
    static func normalized(_ title: String) -> String {
        title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "&", with: " and ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func distance(_ episode: PodcastEpisode, from date: Date) -> TimeInterval {
        abs((episode.publishedAt ?? .distantPast).timeIntervalSince(date))
    }
}
