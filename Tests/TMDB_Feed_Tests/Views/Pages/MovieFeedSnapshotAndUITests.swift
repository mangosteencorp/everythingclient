import SwiftUI
@testable import TMDB_Feed
import ViewInspector
import XCTest

@available(iOS 16.0, *)
final class MovieFeedSnapshotTests: XCTestCase {
    private func makeCache() -> FeedResponseCache {
        FeedResponseCache(defaults: UserDefaults(suiteName: "TMDB_Feed_Snapshot.\(UUID().uuidString)")!)
    }

    func testErrorViewSnapshotHierarchy() throws {
        let view = FeedErrorContentView(
            message: "network connection lost",
            allowsCancelSearch: true,
            retryAction: {},
            cancelAction: {}
        )

        XCTAssertTrue(view.allowsCancelSearch)
        XCTAssertTrue(view.isLikelyNetworkError)
        // Structural fingerprint for network search failure UI
        XCTAssertEqual(
            [view.allowsCancelSearch, view.isLikelyNetworkError],
            [true, true]
        )
    }

    func testServerErrorSnapshotHierarchy() throws {
        let view = FeedErrorContentView(
            message: "500 Internal Server Error",
            allowsCancelSearch: true,
            retryAction: {},
            cancelAction: {}
        )

        XCTAssertFalse(view.isLikelyNetworkError)
        XCTAssertTrue(view.allowsCancelSearch)
        XCTAssertEqual(
            [view.allowsCancelSearch, view.isLikelyNetworkError],
            [true, false]
        )
    }

    func testLoadedMovieTabSnapshot() throws {
        let service = MockAPIService()
        service.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil, page: 1, results: [sampleApeMovie], totalPages: 1, totalResults: 1
        ))
        let vm = MovieFeedViewModel(apiService: service, cache: makeCache())
        vm.loadFeed(.nowPlaying)

        let expectation = expectation(description: "load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let view = MovieFeedTabContent(
            viewModel: vm,
            feedType: .nowPlaying,
            detailRouteBuilder: { _ in 1 },
            useFancyDesign: .constant(false)
        )

        let list = try view.inspect().find(ViewType.List.self)
        XCTAssertNoThrow(try list.find(NavigationMovieRow<Int>.self))
        XCTAssertEqual(vm.movies(for: .nowPlaying).count, 1)
    }

    func testSearchPlaceholderSnapshot() throws {
        let cache = makeCache()
        let view = FeedSearchTabContent(
            movieViewModel: MovieFeedViewModel(apiService: MockAPIService(), cache: cache),
            tvShowViewModel: TVShowFeedViewModel(apiService: MockAPIService(), cache: cache),
            detailRouteBuilder: { _ in 1 },
            tvShowDetailRouteBuilder: { _ in 1 },
            useFancyDesign: .constant(true)
        )

        let pickers = try view.inspect().findAll(ViewType.Picker.self)
        XCTAssertFalse(pickers.isEmpty)
    }

    func testFeedTabFingerprintSnapshot() {
        let fingerprint = FeedTab.allCases.map { "\($0.id):\($0.systemImage)" }
        XCTAssertEqual(
            fingerprint,
            [
                "nowPlaying:play.circle",
                "popular:flame",
                "topRated:star",
                "upcoming:calendar",
                "onTheAir:tv",
                "airingToday:sun.max",
                "search:magnifyingglass",
            ]
        )
    }
}

@available(iOS 16.0, *)
final class MovieFeedUITests: XCTestCase {
    func testCancelSearchClearsErrorState() async {
        let service = MockAPIService()
        service.mockSearchResult = .failure(NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "network connection failed"]
        ))
        let vm = MovieFeedViewModel(
            apiService: service,
            cache: FeedResponseCache(defaults: UserDefaults(suiteName: "TMDB_Feed_UICancel.\(UUID().uuidString)")!)
        )

        vm.searchQuery = "batman"

        let errorExpectation = expectation(description: "error")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if case .error = vm.state {
                errorExpectation.fulfill()
            }
        }
        await fulfillment(of: [errorExpectation], timeout: 2.0)

        vm.cancelSearch()
        XCTAssertEqual(vm.searchQuery, "")
        if case .initial = vm.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected initial state after cancel, got \(vm.state)")
        }
    }

    func testRefreshFallsBackToCacheOnFailure() async {
        let defaults = UserDefaults(suiteName: "TMDB_Feed_CacheRefresh.\(UUID().uuidString)")!
        let cache = FeedResponseCache(defaults: defaults)
        cache.saveMovies([sampleApeMovie], for: .nowPlaying)

        let service = MockAPIService()
        service.mockNowPlayingResult = .failure(NSError(domain: "Test", code: -1))

        let vm = MovieFeedViewModel(apiService: service, cache: cache)
        XCTAssertEqual(vm.movies(for: .nowPlaying).count, 1)

        await vm.refresh(.nowPlaying)
        XCTAssertEqual(vm.movies(for: .nowPlaying).count, 1)
        if case .loaded(let movies) = vm.state {
            XCTAssertEqual(movies.count, 1)
        } else {
            XCTFail("Expected cached loaded state, got \(vm.state)")
        }
    }
}
