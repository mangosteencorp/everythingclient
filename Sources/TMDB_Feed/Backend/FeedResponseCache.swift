import Foundation
import TMDB_Shared_Backend

/// Persists feed responses so lists can load offline after a successful fetch.
final class FeedResponseCache {
    static let shared = FeedResponseCache()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveMovies(_ movies: [Movie], for feedType: MovieFeedType) {
        guard let data = try? encoder.encode(movies) else { return }
        defaults.set(data, forKey: movieKey(feedType))
    }

    func loadMovies(for feedType: MovieFeedType) -> [Movie]? {
        guard let data = defaults.data(forKey: movieKey(feedType)),
              let movies = try? decoder.decode([Movie].self, from: data),
              !movies.isEmpty else {
            return nil
        }
        return movies
    }

    func saveTVShows(_ shows: [TVShow], for feedType: TVShowFeedType) {
        guard let data = try? encoder.encode(shows) else { return }
        defaults.set(data, forKey: tvKey(feedType))
    }

    func loadTVShows(for feedType: TVShowFeedType) -> [TVShow]? {
        guard let data = defaults.data(forKey: tvKey(feedType)),
              let shows = try? decoder.decode([TVShow].self, from: data),
              !shows.isEmpty else {
            return nil
        }
        return shows
    }

    private func movieKey(_ feedType: MovieFeedType) -> String {
        "tmdb.feed.cache.movies.\(feedType.rawValue)"
    }

    private func tvKey(_ feedType: TVShowFeedType) -> String {
        "tmdb.feed.cache.tv.\(feedType.rawValue)"
    }
}
