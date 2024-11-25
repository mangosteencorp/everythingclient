enum Route: Equatable {
    case popularMovies
    case accountInfo
    case authStep1
    case authStep3
    case logOut
    case setfavoriteMovie(String)
    case getFavoritesMovies(String)
    case topRatedMovies
    case movie(String)
    case searchMovie
    
    
    var rawValue: String {
        switch self {
        case .setfavoriteMovie(let accID):
             return "account/\(accID)/favorite"
        case .popularMovies:
             return "movie/popular"
        case .accountInfo:
            return "account"
        case .authStep1:
            return "authentication/token/new"
        case .authStep3:
            return "authentication/session/new"
        case .logOut:
            return "authentication/session"
        case .getFavoritesMovies(let accID):
            return "account/\(accID)/favorite/movies"
        case .topRatedMovies:
            return "movie/top_rated"
        case .movie(let id):
            return "movie/\(id)"
        case .searchMovie:
            return"search/movie"
        }
    }
    
}
