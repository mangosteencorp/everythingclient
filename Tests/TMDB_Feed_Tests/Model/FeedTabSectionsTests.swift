import CoreFeatures
@testable import TMDB_Feed
import XCTest

/// The sectioned shell builds its sidebar straight from `FeedTab.sections`, so a new feed tab
/// that nobody adds to a section would silently disappear from that design.
final class FeedTabSectionsTests: XCTestCase {
    func testEveryNonSearchTabAppearsExactlyOnce() {
        let rows = FeedTab.sections.flatMap(\.rows)
        let expected = FeedTab.allCases.filter { $0 != .search }

        XCTAssertEqual(Set(rows), Set(expected))
        XCTAssertEqual(rows.count, expected.count, "a tab is listed in more than one section")
    }

    func testSearchIsNotASidebarRow() {
        XCTAssertFalse(FeedTab.sections.flatMap(\.rows).contains(.search))
    }

    func testCustomizationIDsAreStableAndUnique() {
        let ids = FeedTab.allCases.map(\.customizationID)

        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(FeedTab.popular.customizationID, "tab.feed.popular")
    }
}
