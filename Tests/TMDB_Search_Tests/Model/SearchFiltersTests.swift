@testable import TMDB_Search
import XCTest

/// The chips and what each scope's endpoint may be sent.
final class SearchFiltersTests: XCTestCase {
    /// Every chip is offered somewhere, and each scope offers exactly its endpoint's parameters.
    func testEveryScopeOffersTheChipsItsEndpointAccepts() {
        let expected: [SearchScope: [FilterType]] = [
            .multi: [.includeAdult, .language],
            .movies: [.includeAdult, .language, .primaryReleaseYear, .region, .year],
            .tvShows: [.includeAdult, .language, .firstAirDateYear, .year],
            .people: [.includeAdult, .language],
            .collections: [.includeAdult, .language, .region],
            .companies: [],
            .keywords: [],
        ]

        for scope in SearchScope.allCases {
            XCTAssertEqual(scope.supportedFilters, expected[scope], "\(scope)")
        }
        XCTAssertEqual(Set(SearchScope.allCases.flatMap(\.supportedFilters)), Set(FilterType.allCases))
    }

    func testNarrowingClearsFiltersTheScopeDoesNotSupport() {
        let filters = SearchFilters(
            includeAdult: true,
            language: "fr",
            primaryReleaseYear: "2021",
            region: "FR",
            year: "2020"
        )

        XCTAssertEqual(filters.narrowed(to: .movies), filters)
        XCTAssertFalse(filters.narrowed(to: .keywords).hasActiveFilters)
        XCTAssertNil(filters.narrowed(to: .people).region)
        XCTAssertNil(filters.narrowed(to: .tvShows).primaryReleaseYear)
        XCTAssertNil(filters.narrowed(to: .tvShows).region)
        XCTAssertEqual(filters.narrowed(to: .tvShows).year, "2020")
    }

    func testResettingAndClearingFilters() {
        var filters = SearchFilters(includeAdult: true, firstAirDateYear: "2019", region: "FR")

        filters.reset(.includeAdult)
        filters.reset(.region)
        XCTAssertEqual(filters, SearchFilters(firstAirDateYear: "2019"))
        XCTAssertTrue(filters.isActive(.firstAirDateYear))
        XCTAssertFalse(filters.isActive(.year))

        filters.clearAll()
        XCTAssertFalse(filters.hasActiveFilters)
    }

    /// A chip reads its value the way the user would say it, not as the code TMDB takes.
    func testChipValuesAreReadable() {
        let filters = SearchFilters(includeAdult: true, language: "fr", primaryReleaseYear: "2021", region: "JP")

        XCTAssertEqual(filters.displayValue(for: .includeAdult), L10n.filterValueOn)
        XCTAssertEqual(filters.displayValue(for: .language), Locale.current.localizedString(forIdentifier: "fr"))
        XCTAssertNotEqual(filters.displayValue(for: .language), "fr")
        XCTAssertEqual(filters.displayValue(for: .region), Locale.current.localizedString(forRegionCode: "JP"))
        XCTAssertEqual(filters.displayValue(for: .primaryReleaseYear), "2021")
        XCTAssertNil(filters.displayValue(for: .year))
    }

    /// Year pickers only offer what TMDB accepts, newest first, so no typed "20" reaches it.
    func testYearOptionsAreFourDigitYearsNewestFirst() {
        let years = FilterType.year.options

        XCTAssertEqual(years.last, "1900")
        XCTAssertTrue(years.allSatisfy { $0.count == 4 && Int($0) != nil })
        XCTAssertEqual(years, years.sorted(by: >))
        XCTAssertEqual(FilterType.firstAirDateYear.options, years)
        XCTAssertTrue(FilterType.includeAdult.options.isEmpty)
    }
}
