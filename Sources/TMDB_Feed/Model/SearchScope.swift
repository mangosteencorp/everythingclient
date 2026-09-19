import Foundation

/// Every search endpoint TMDB exposes, as one picker's worth of scopes.
public enum SearchScope: String, CaseIterable, Identifiable, Hashable {
    /// `search/multi` — movies, shows and people ranked together.
    case multi
    case movies
    case tvShows
    case people
    case collections
    case companies
    case keywords

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .multi: return L10n.searchScopeAll
        case .movies: return L10n.feedSearchMovies
        case .tvShows: return L10n.feedSearchTv
        case .people: return L10n.searchScopePeople
        case .collections: return L10n.searchScopeCollections
        case .companies: return L10n.searchScopeCompanies
        case .keywords: return L10n.searchScopeKeywords
        }
    }

    public var systemImage: String {
        switch self {
        case .multi: return "sparkle.magnifyingglass"
        case .movies: return "film"
        case .tvShows: return "tv"
        case .people: return "person.2"
        case .collections: return "square.stack"
        case .companies: return "building.2"
        case .keywords: return "tag"
        }
    }
}

/// What a result is, which decides its icon and whether tapping it goes anywhere.
public enum SearchResultKind: String, Hashable {
    case movie, tvShow, person, collection, company, keyword

    public var systemImage: String {
        switch self {
        case .movie: return "film"
        case .tvShow: return "tv"
        case .person: return "person.crop.circle"
        case .collection: return "square.stack"
        case .company: return "building.2"
        case .keyword: return "tag"
        }
    }
}

/// One row of results, normalised so all seven endpoints render through a single list.
public struct SearchResultItem: Identifiable, Hashable {
    /// TMDB ids are only unique per media type, so the list id carries the kind as well.
    public var id: String { "\(kind.rawValue)-\(tmdbID)" }
    public let tmdbID: Int
    public let kind: SearchResultKind
    public let title: String
    public let subtitle: String?
    /// Poster, profile or logo path — whichever this kind has.
    public let imagePath: String?
    public let voteAverage: Double?

    public init(
        tmdbID: Int,
        kind: SearchResultKind,
        title: String,
        subtitle: String? = nil,
        imagePath: String? = nil,
        voteAverage: Double? = nil
    ) {
        self.tmdbID = tmdbID
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.imagePath = imagePath
        self.voteAverage = voteAverage
    }
}

public struct SearchResultPage {
    public let items: [SearchResultItem]
    public let page: Int
    public let totalPages: Int

    public init(items: [SearchResultItem], page: Int, totalPages: Int) {
        self.items = items
        self.page = page
        self.totalPages = totalPages
    }

    public var hasMore: Bool { page < totalPages }
}
