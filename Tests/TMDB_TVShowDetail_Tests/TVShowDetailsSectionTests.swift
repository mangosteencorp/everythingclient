import Tests_Shared_Helpers
import TMDB_Shared_Backend
@testable import TMDB_TVShowDetail
import XCTest

@available(iOS 15, *)
final class TVShowDetailsSectionTests: XCTestCase {
    private func makeSection(lastAirDate: String = #""2019-05-19""#) throws -> TVShowDetailsSection {
        let json = TMDBJSON.tvShowDetail().replacingOccurrences(
            of: #""last_air_date": "2019-05-19""#,
            with: #""last_air_date": \#(lastAirDate)"#
        )
        return TVShowDetailsSection(tvShow: try JSONFixture.decode(TVShowDetailModel.self, from: json))
    }

    func testLastAirDateShowsThePlainDate() throws {
        XCTAssertTrue(try makeSection().rowTitles.contains("Last air date: 2019-05-19"))
    }

    func testMissingLastAirDateShowsThePlaceholder() throws {
        XCTAssertTrue(try makeSection(lastAirDate: "null").rowTitles.contains("Last air date: \(L10n.Tvshow.Detail.tba)"))
    }

    func testNoRowInterpolatesAnOptional() throws {
        for section in [try makeSection(), try makeSection(lastAirDate: "null")] {
            XCTAssertFalse(section.rowTitles.contains { $0.contains("Optional(") }, "\(section.rowTitles)")
        }
    }
}
