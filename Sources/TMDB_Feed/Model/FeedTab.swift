import CoreFeatures
import Foundation

/// Top-level tabs for the feed screen.
public enum FeedTab: String, CaseIterable, Identifiable, Hashable {
    case nowPlaying
    case popular
    case topRated
    case upcoming
    case onTheAir
    case airingToday

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .nowPlaying:
            return L10n.feedNowPlaying
        case .popular:
            return L10n.feedPopular
        case .topRated:
            return L10n.feedTopRated
        case .upcoming:
            return L10n.feedUpcoming
        case .onTheAir:
            return L10n.feedOnTheAir
        case .airingToday:
            return L10n.feedAiringToday
        }
    }

    public var systemImage: String {
        switch self {
        case .nowPlaying:
            return "play.circle"
        case .popular:
            return "flame"
        case .topRated:
            return "star"
        case .upcoming:
            return "calendar"
        case .onTheAir:
            return "tv"
        case .airingToday:
            return "sun.max"
        }
    }

    public var movieFeedType: MovieFeedType? {
        switch self {
        case .nowPlaying: return .nowPlaying
        case .popular: return .popular
        case .topRated: return .topRated
        case .upcoming: return .upcoming
        case .onTheAir, .airingToday: return nil
        }
    }

    public var tvShowFeedType: TVShowFeedType? {
        switch self {
        case .onTheAir: return .onTheAir
        case .airingToday: return .airingToday
        case .nowPlaying, .popular, .topRated, .upcoming: return nil
        }
    }
}

// MARK: - Sectioned shell support

extension FeedTab: ShellTabItem {
    public var customizationID: String { "tab.feed.\(rawValue)" }

    /// The feed categories grouped for a sectioned shell (sidebar on iPad, a pushable list on
    /// iPhone). Search is not here at all: it is a root tab of its own, in `TMDB_Search`.
    public static var sections: [ShellSection<FeedTab>] {
        [
            ShellSection(
                id: "movies",
                title: L10n.feedSectionMovies,
                systemImage: "film",
                rows: [.nowPlaying, .popular, .topRated, .upcoming]
            ),
            ShellSection(
                id: "tv",
                title: L10n.feedSectionTv,
                systemImage: "tv",
                rows: [.onTheAir, .airingToday]
            ),
        ]
    }
}
