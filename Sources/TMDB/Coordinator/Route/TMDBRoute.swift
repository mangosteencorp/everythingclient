import TMDB_Discover
import TMDB_Feed
public enum TMDBRoute: Route {
    case movieDetail(MovieRouteModel)
    case tvShowDetail(Int)
    case movieList(AdditionalMovieListParams)
    case tvShowList(TMDB_Discover.TVShowFeedType)
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .movieDetail(movie):
            hasher.combine(movie.id)
        case let .tvShowDetail(id):
            hasher.combine(id)
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
        case let (.movieList(lParams), .movieList(rParams)):
            return lParams == rParams
        case let (.tvShowList(lType), .tvShowList(rType)):
            return lType == rType
        default:
            return false
        }
    }
}
