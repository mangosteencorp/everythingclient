public enum TMDBRoute: Route {
    case movieDetail(MovieRouteModel)
    case tvShowDetail(Int)
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .movieDetail(let movie):
            hasher.combine(movie.id)
        case .tvShowDetail(let id):
            hasher.combine(id)
        }
    }
    
    public static func == (lhs: TMDBRoute, rhs: TMDBRoute) -> Bool {
        switch (lhs, rhs) {
        case (.movieDetail(let lMovie), .movieDetail(let rMovie)):
            return lMovie.id == rMovie.id
        case (.tvShowDetail(let lId), .tvShowDetail(let rId)):
            return lId == rId
        default:
            return false
        }
    }
} 