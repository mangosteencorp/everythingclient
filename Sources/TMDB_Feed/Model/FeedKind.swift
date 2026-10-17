import Foundation

/// One TMDB feed: a movie list or a TV list. `FeedPage` shows exactly one of these; grouping
/// several into tabs or sections is the host's job.
public enum FeedKind: String, CaseIterable, Identifiable, Hashable {
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

public enum MovieFeedType: String, CaseIterable, Identifiable {
    case nowPlaying
    case popular
    case topRated
    case upcoming

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .nowPlaying:
            return L10n.feedNowPlaying
        case .popular:
            return L10n.feedPopular
        case .topRated:
            return L10n.feedTopRated
        case .upcoming:
            return L10n.feedUpcoming
        }
    }
}

public enum TVShowFeedType: String, CaseIterable, Identifiable {
    case airingToday
    case onTheAir

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .airingToday:
            return L10n.feedAiringToday
        case .onTheAir:
            return L10n.feedOnTheAir
        }
    }
}

public enum ContentFeedType: String, CaseIterable, Identifiable {
    case movies
    case tvShows

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .movies:
            return L10n.feedSectionMovies
        case .tvShows:
            return L10n.feedSectionTv
        }
    }
}
