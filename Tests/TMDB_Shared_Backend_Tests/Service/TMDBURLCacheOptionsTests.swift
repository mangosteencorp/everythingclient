@testable import TMDB_Shared_Backend
import XCTest

final class TMDBURLCacheOptionsTests: XCTestCase {
    func testDefaultOptionsAreDisabled() {
        XCTAssertFalse(TMDBURLCacheOptions().isEnabled)
        XCTAssertEqual(TMDBURLCacheOptions.disabled, TMDBURLCacheOptions(isEnabled: false))
    }

    func testEnabledGETWithoutAuthUsesCachePolicy() {
        let service = TMDBAPIService(apiKey: "test", urlCacheOptions: .enabled)
        XCTAssertTrue(service.shouldUseURLCache(for: .nowPlaying()))
        XCTAssertEqual(service.cachePolicy(for: .nowPlaying()), .returnCacheDataElseLoad)
        XCTAssertEqual(service.cachePolicy(for: .searchMovie(query: "batman")), .returnCacheDataElseLoad)
    }

    func testDisabledIgnoresCacheEvenForGET() {
        let service = TMDBAPIService(apiKey: "test", urlCacheOptions: .disabled)
        XCTAssertFalse(service.shouldUseURLCache(for: .nowPlaying()))
        XCTAssertEqual(service.cachePolicy(for: .nowPlaying()), .reloadIgnoringLocalCacheData)
    }

    func testAuthenticatedGETBypassesCacheWhenEnabled() {
        let service = TMDBAPIService(apiKey: "test", urlCacheOptions: .enabled)
        XCTAssertFalse(service.shouldUseURLCache(for: .getFavoriteMovies(accountId: "1")))
        XCTAssertEqual(
            service.cachePolicy(for: .getFavoriteMovies(accountId: "1")),
            .reloadIgnoringLocalCacheData
        )
    }

    func testPOSTBypassesCacheWhenEnabled() {
        let service = TMDBAPIService(apiKey: "test", urlCacheOptions: .enabled)
        XCTAssertFalse(service.shouldUseURLCache(for: .authNewSession(requestToken: "token")))
        XCTAssertEqual(
            service.cachePolicy(for: .authNewSession(requestToken: "token")),
            .reloadIgnoringLocalCacheData
        )
    }
}
