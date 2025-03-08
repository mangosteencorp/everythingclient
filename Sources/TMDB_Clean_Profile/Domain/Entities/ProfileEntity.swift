import Foundation

struct ProfileEntity {
    let accountInfo: AccountInfoEntity
    let favoriteMovies: [MovieEntity]?
    let favoriteTVShows: [TVShowEntity]?
    let watchlistTVShows: [TVShowEntity]?
}
