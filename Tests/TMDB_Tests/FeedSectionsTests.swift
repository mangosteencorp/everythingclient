@testable import TMDB
import TMDB_Feed
import XCTest

/// The sectioned shell builds its sidebar straight from `TabRoute.feedSections`, so a new feed
/// kind that is not listed there would silently never appear.
final class FeedSectionsTests: XCTestCase {
    func testEveryFeedKindAppearsInExactlyOneSection() {
        let rows = TabRoute.feedSections.flatMap(\.rows)
        XCTAssertEqual(Set(rows), Set(FeedKind.allCases.map(TabRoute.feedRow)))
        XCTAssertEqual(rows.count, FeedKind.allCases.count, "a feed is listed in more than one section")
    }

    func testCustomizationIDsAreUniqueAndStable() {
        let ids = FeedKind.allCases.map { TabRoute.feedRow($0).customizationID }
        XCTAssertEqual(Set(ids).count, ids.count)
        // Stored by `TabViewCustomization`: changing it loses the user's sidebar order.
        XCTAssertEqual(TabRoute.feedRow(.popular).customizationID, "tab.feed.popular")
    }
}
