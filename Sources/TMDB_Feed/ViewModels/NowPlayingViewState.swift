import Foundation

public enum NowPlayingViewState: Equatable {
    case initial
    case loading
    case loaded([Movie])
    case searchResults([Movie])
    case error(String)

    var movies: [Movie] {
        switch self {
        case .loaded(let movies), .searchResults(let movies):
            return movies
        case .initial, .loading, .error:
            return []
        }
    }

    public static func == (lhs: NowPlayingViewState, rhs: NowPlayingViewState) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial):
            return true
        case (.loading, .loading):
            return true
        case (.loaded(let lhsMovies), .loaded(let rhsMovies)):
            return lhsMovies.map(\.id) == rhsMovies.map((\.id))
        case (.searchResults(let lhsMovies), .searchResults(let rhsMovies)):
            return lhsMovies.map(\.id) == rhsMovies.map((\.id))
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
