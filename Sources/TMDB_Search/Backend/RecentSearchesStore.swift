import Foundation

/// Where the search page keeps the queries you committed to, newest first.
///
/// A protocol so previews and tests can hand the page a fixed list instead of whatever the
/// simulator's defaults happen to hold.
public protocol RecentSearchesStoring {
    func load() -> [String]
    func save(_ searches: [String])
}

/// A few short strings: `UserDefaults` is all the persistence they need.
public struct UserDefaultsRecentSearchesStore: RecentSearchesStoring {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "tmdb.search.recentSearches") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    public func save(_ searches: [String]) {
        defaults.set(searches, forKey: key)
    }
}
