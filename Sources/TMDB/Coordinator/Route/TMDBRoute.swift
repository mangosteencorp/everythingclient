import TMDB_Discover
import TMDB_Feed
import TMDB_Search
public enum TMDBRoute: Route {
    case movieDetail(MovieRouteModel)
    case tvShowDetail(Int)
    case personDetail(Int)
    case photoSlides(PhotoSlidesRouteModel)
    case pokedex
    case movieList(AdditionalMovieListParams)
    case tvShowList(TMDB_Discover.TVShowFeedType)

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
        case let .movieDetail(movie):
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
        case let (.movieDetail(lMovie), .movieDetail(rMovie)):
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
