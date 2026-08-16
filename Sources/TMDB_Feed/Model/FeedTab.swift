import Foundation

/// Top-level tabs for the feed screen.
public enum FeedTab: String, CaseIterable, Identifiable, Hashable {
    case nowPlaying
    case popular
    case topRated
    case upcoming
    case onTheAir
    case airingToday
    case search

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
        case .search:
            return L10n.feedSearch
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
        case .search:
            return "magnifyingglass"
        }
    }

    public var movieFeedType: MovieFeedType? {
        switch self {
        case .nowPlaying: return .nowPlaying
        case .popular: return .popular
        case .topRated: return .topRated
        case .upcoming: return .upcoming
        case .onTheAir, .airingToday, .search: return nil
        }
    }

    public var tvShowFeedType: TVShowFeedType? {
        switch self {
        case .onTheAir: return .onTheAir
        case .airingToday: return .airingToday
        case .nowPlaying, .popular, .topRated, .upcoming, .search: return nil
        }
    }
}
