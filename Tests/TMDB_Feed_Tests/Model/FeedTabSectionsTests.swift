import CoreFeatures
@testable import TMDB_Feed
import XCTest

/// The sectioned shell builds its sidebar straight from `FeedTab.sections`, so a new feed tab
/// that nobody adds to a section would silently disappear from that design.
final class FeedTabSectionsTests: XCTestCase {
    func testEveryTabAppearsExactlyOnce() {
        let rows = FeedTab.sections.flatMap(\.rows)

        XCTAssertEqual(Set(rows), Set(FeedTab.allCases))
        XCTAssertEqual(rows.count, FeedTab.allCases.count, "a tab is listed in more than one section")
    }

    func testCustomizationIDsAreStableAndUnique() {
        let ids = FeedTab.allCases.map(\.customizationID)

        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(FeedTab.popular.customizationID, "tab.feed.popular")
    }
}
