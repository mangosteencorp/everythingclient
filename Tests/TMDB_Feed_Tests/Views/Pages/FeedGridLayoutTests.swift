import CoreFeatures
import SwiftUI
@testable import TMDB_Feed
import TMDB_Shared_UI
import XCTest

/// The poster grid on an iPad-sized window. Cells used to be one or two title lines tall, so
/// neighbours in a row had different heights.
@available(iOS 16.0, *)
@MainActor
final class FeedGridLayoutTests: XCTestCase {
    /// Height of the grid's scroll content for one row of posters with these titles.
    private func gridContentHeight(titles: [String]) throws -> CGFloat {
        let items = titles.indices.map { index in
            Movie(
                id: index, originalTitle: titles[index], title: titles[index], overview: "",
                posterPath: nil, backdropPath: nil, popularity: 1, voteAverage: 7, voteCount: 1,
                releaseDate: "2026-01-01", genres: nil, video: false
            ).feedItem(route: index)
        }
        let view = NavigationStack {
            FeedItemsView(items: items, accessibilityIdentifier: "grid", onItemAppear: { _ in })
        }
        .designStyle(FeedContentDesign.grid)
        .environment(\.horizontalSizeClass, .regular)

        // iPad 11-inch, landscape: nine posters per row.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1194, height: 834))
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        return try XCTUnwrap(scrollView(in: window)).contentSize.height
    }

    private func scrollView(in view: UIView) -> UIScrollView? {
        (view as? UIScrollView) ?? view.subviews.lazy.compactMap { self.scrollView(in: $0) }.first
    }

    func testGridCellsAreTheSameHeightForOneAndTwoLineTitles() throws {
        let oneLine = try gridContentHeight(titles: ["The Uprising", "Colony", "Verity"])
        let mixed = try gridContentHeight(titles: ["The Uprising", "Colony", "The Love Hypothesis"])

        XCTAssertGreaterThan(oneLine, PosterSize.grid.height)
        XCTAssertEqual(oneLine, mixed, "a two-line title must not make its cell taller than its neighbours")
    }
}
