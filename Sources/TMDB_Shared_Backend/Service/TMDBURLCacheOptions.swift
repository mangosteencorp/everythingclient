import Foundation

/// Controls whether `TMDBAPIService` uses `URLSession` / `URLCache` for responses.
///
/// - Default for `TMDB_Shared_Backend.configure` is **off**.
/// - When enabled, **GET** requests that do **not** require authentication use the
///   session URL cache (including offline fallback via `.returnCacheDataElseLoad`).
/// - Authenticated or non-GET requests always bypass the cache.
public struct TMDBURLCacheOptions: Equatable, Sendable {
    public var isEnabled: Bool

    public init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    public static let disabled = TMDBURLCacheOptions(isEnabled: false)
    public static let enabled = TMDBURLCacheOptions(isEnabled: true)
}
