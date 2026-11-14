import TMDB_Discover
import TMDB_Feed
import TMDB_Search
public enum TMDBRoute: Route {
    /// `window` is what the detail page can swipe through: the feed rows around `movie`, that
    /// movie included. Empty for a movie reached on its own (search, people, keywords).
    case movieDetail(MovieRouteModel, window: [MovieRouteModel] = [])
    case tvShowDetail(Int)
    case personDetail(Int)
    case photoSlides(PhotoSlidesRouteModel)
    case pokedex
    case movieList(AdditionalMovieListParams)
    case tvShowList(TMDB_Discover.TVShowFeedType)

    /// A feed movie's detail, swipeable through the feed rows around it. Shared by every feed
    /// in every shell, so a poster always leads to the same route.
    public static func movie(_ movie: TMDB_Feed.Movie, in window: ArraySlice<TMDB_Feed.Movie>) -> TMDBRoute {
        .movieDetail(MovieRouteModel(movie), window: window.map(MovieRouteModel.init))
    }

    /// Where a search result leads.
    ///
    /// Search spans more kinds than the app has pages for: collections, companies and keywords
    /// return `nil` and render as plain, non-pushing rows.
    public static func search(for item: SearchResultItem) -> TMDBRoute? {
        switch item.kind {
        case .movie: return .movieDetail(MovieRouteModel(id: item.tmdbID))
        case .tvShow: return .tvShowDetail(item.tmdbID)
        case .person: return .personDetail(item.tmdbID)
        case .collection, .company, .keyword: return nil
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        // Only the tapped movie: the same title from another feed position is the same route.
        case let .movieDetail(movie, _):
            hasher.combine(movie.id)
        case let .tvShowDetail(id):
            hasher.combine(id)
        case let .personDetail(id):
            hasher.combine(id)
        case let .photoSlides(model):
            hasher.combine(model.imagePaths)
            hasher.combine(model.initialIndex)
        case .pokedex:
            hasher.combine("pokedex")
        case let .movieList(params):
            hasher.combine(params)
        case let .tvShowList(type):
            hasher.combine(type)
        }
    }

    public static func == (lhs: TMDBRoute, rhs: TMDBRoute) -> Bool {
        switch (lhs, rhs) {
        case let (.movieDetail(lMovie, _), .movieDetail(rMovie, _)):
            return lMovie.id == rMovie.id
        case let (.tvShowDetail(lId), .tvShowDetail(rId)):
            return lId == rId
        case let (.personDetail(lId), .personDetail(rId)):
            return lId == rId
        case let (.photoSlides(lModel), .photoSlides(rModel)):
            return lModel == rModel
        case (.pokedex, .pokedex):
            return true
        case let (.movieList(lParams), .movieList(rParams)):
            return lParams == rParams
        case let (.tvShowList(lType), .tvShowList(rType)):
            return lType == rType
        default:
            return false
        }
    }
}
