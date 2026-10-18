import CoreFeatures
import SwiftUI
@testable import TMDB_Feed
import TMDB_Shared_UI
import ViewInspector
import XCTest

@available(iOS 16.0, *)
@MainActor
final class MovieFeedSnapshotTests: XCTestCase {
    func testErrorViewSnapshotHierarchy() throws {
        let view = FeedErrorContentView(
            message: "network connection lost",
            allowsCancelSearch: true,
            retryAction: {},
            cancelAction: {}
        )

        XCTAssertTrue(view.allowsCancelSearch)
        XCTAssertTrue(view.isLikelyNetworkError)
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

    func testLoadedMovieFeedSnapshot() async throws {
        DesignCoordinator.shared.select(FeedContentDesign.list)
        let service = MockAPIService()
        service.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil, page: 1, results: [sampleApeMovie], totalPages: 1, totalResults: 1
        ))
        let vm = MovieFeedViewModel(feedType: .nowPlaying, apiService: service)
        vm.load()
        await waitUntil { vm.state.kind == .loaded }

        let view = MovieFeedContent(viewModel: vm, detailRouteBuilder: { _ in 1 })

        let list = try view.inspect().find(ViewType.List.self)
        XCTAssertNoThrow(try list.find(FeedItemRow<Int>.self))
        XCTAssertEqual(vm.state.items.count, 1)
    }

    func testFeedKindFingerprintSnapshot() {
        let fingerprint = FeedKind.allCases.map { "\($0.id):\($0.systemImage)" }
        XCTAssertEqual(
            fingerprint,
            [
                "nowPlaying:play.circle",
                "popular:flame",
                "topRated:star",
                "upcoming:calendar",
                "onTheAir:tv",
                "airingToday:sun.max",
            ]
        )
    }
}

@available(iOS 16.0, *)
@MainActor
final class MovieFeedUITests: XCTestCase {
    func testRefreshFallsBackToInMemoryOnFailure() async {
        let service = MockAPIService()
        service.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil, page: 1, results: [sampleApeMovie], totalPages: 1, totalResults: 1
        ))
        let vm = MovieFeedViewModel(feedType: .nowPlaying, apiService: service)
        vm.load()
        await waitUntil { vm.state.kind == .loaded }

        service.mockNowPlayingResult = .failure(NSError(domain: "Test", code: -1))
        await vm.refresh()
        XCTAssertEqual(vm.state.items.count, 1)
        XCTAssertEqual(vm.state.kind, .loaded)
    }
}
