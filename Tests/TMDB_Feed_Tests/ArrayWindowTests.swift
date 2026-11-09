@testable import TMDB_Feed
import XCTest

final class ArrayWindowTests: XCTestCase {
    private let feed = Array(0 ..< 30)

    func testMiddleItemGetsRadiusOnBothSides() {
        XCTAssertEqual(Array(feed.window(around: 15)), Array(5 ... 25))
    }

    func testFirstItemOnlyLooksForward() {
        XCTAssertEqual(Array(feed.window(around: 0)), Array(0 ... 10))
    }

    func testLastItemOnlyLooksBack() {
        XCTAssertEqual(Array(feed.window(around: 29)), Array(19 ... 29))
    }

    func testFeedShorterThanWindowIsReturnedWhole() {
        XCTAssertEqual(Array([7, 8, 9].window(around: 1)), [7, 8, 9])
    }

    func testDefaultRadiusIsTen() {
        XCTAssertEqual(feed.window(around: 15).count, 2 * 10 + 1)
        XCTAssertEqual(movieDetailWindowRadius, 10)
    }
}
