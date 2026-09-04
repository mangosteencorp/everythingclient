import TMDB_Feed
#if os(iOS)
import TMDB_Discover
#endif

public enum TMDBRoute: Route {
    case movieDetail(MovieRouteModel)
    case tvShowDetail(Int)
    case personDetail(Int)
    case photoSlides(PhotoSlidesRouteModel)
    case pokedex
    case movieList(AdditionalMovieListParams)
    // `TMDB_Discover` is UIKit-backed and ships on iOS only; see `Package.swift`.
    #if os(iOS)
    case tvShowList(TMDB_Discover.TVShowFeedType)
    #endif

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
        #if os(iOS)
        case let .tvShowList(type):
            hasher.combine(type)
        #endif
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
        #if os(iOS)
        case let (.tvShowList(lType), .tvShowList(rType)):
            return lType == rType
        #endif
        default:
            return false
        }
    }
}
