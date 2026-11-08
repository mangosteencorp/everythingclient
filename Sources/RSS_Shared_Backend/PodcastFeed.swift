import Foundation

/// The podcast feeds the app knows about, in one place.
public enum PodcastFeed {
    /// IGN's "Movie Reviews" show (Apple Podcasts id 1147278052): one "<Movie Title> Review" episode per film.
    public static let ignMovieReviews = URL(string: "https://feeds.megaphone.fm/ign-movie-review")!
}
