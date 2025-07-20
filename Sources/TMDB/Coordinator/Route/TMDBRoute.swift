import TMDB_Feed
public enum TMDBRoute: Route {
    case movieDetail(MovieRouteModel)
    case tvShowDetail(Int)
    case movieList(AdditionalMovieListParams)
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .movieDetail(movie):
            hasher.combine(movie.id)
        case let .tvShowDetail(id):
            hasher.combine(id)
        case let .movieList(params):
            hasher.combine(params)
        }
    }

    public static func == (lhs: TMDBRoute, rhs: TMDBRoute) -> Bool {
        switch (lhs, rhs) {
        case let (.movieDetail(lMovie), .movieDetail(rMovie)):
            return lMovie.id == rMovie.id
        case let (.tvShowDetail(lId), .tvShowDetail(rId)):
            return lId == rId
        default:
            return false
        }
    }
}
