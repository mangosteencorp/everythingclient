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
        case .movies: return L10n.searchScopeMovies
        case .tvShows: return L10n.searchScopeTv
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

    /// Which filter chips this scope can actually act on: every query parameter its endpoint
    /// takes besides `query` and `page`.
    ///
    /// TMDB accepts a different query-parameter set per search endpoint — `search/keyword` and
    /// `search/company` take nothing but `query` and `page`. Offering a chip that the request
    /// would silently drop is worse than not offering it, so the picker only shows what the
    /// endpoint honours.
    public var supportedFilters: [FilterType] {
        switch self {
        case .movies:
            return [.includeAdult, .language, .primaryReleaseYear, .region, .year]
        case .tvShows:
            // `search/tv` has no `region`, and two years: the first air date alone, or any air
            // date including episodes.
            return [.includeAdult, .language, .firstAirDateYear, .year]
        case .multi, .people:
            return [.includeAdult, .language]
        case .collections:
            return [.includeAdult, .language, .region]
        case .keywords, .companies:
            return []
        }
    }
}

/// What a result is, which decides its icon and whether tapping it goes anywhere.
public enum SearchResultKind: String, Hashable {
    case movie, tvShow, person, collection, company, keyword

    /// The badge text that tells mixed "All" results apart.
    public var title: String {
        switch self {
        case .movie: return L10n.searchKindMovie
        case .tvShow: return L10n.searchKindTvShow
        case .person: return L10n.searchKindPerson
        case .collection: return L10n.searchKindCollection
        case .company: return L10n.searchKindCompany
        case .keyword: return L10n.searchKindKeyword
        }
    }

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
    /// Release or first-air date for movies and shows, department for people, origin country
    /// for companies.
    public let subtitle: String?
    /// The synopsis; for people, the titles they are known for.
    public let overview: String?
    /// Poster, profile or logo path — whichever this kind has.
    public let imagePath: String?
    public let voteAverage: Double?

    public init(
        tmdbID: Int,
        kind: SearchResultKind,
        title: String,
        subtitle: String? = nil,
        overview: String? = nil,
        imagePath: String? = nil,
        voteAverage: Double? = nil
    ) {
        self.tmdbID = tmdbID
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.overview = overview
        self.imagePath = imagePath
        self.voteAverage = voteAverage
    }

    /// "2021" out of a "2021-10-22" release date; `nil` for kinds whose subtitle is not a date.
    public var year: String? {
        guard kind == .movie || kind == .tvShow, let year = subtitle?.prefix(4),
              year.count == 4, year.allSatisfy(\.isNumber) else { return nil }
        return String(year)
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
