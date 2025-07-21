@testable import TMDB_Shared_Backend
import XCTest

final class TrendingAllTests: XCTestCase {
    func testTrendingAllParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "trending_all", withExtension: "json"))
        let data = try XCTUnwrap(Data(contentsOf: url))

        var trendingAll: TrendingAllResultModel?
        XCTAssertNoThrow(trendingAll = try JSONDecoder().decode(TrendingAllResultModel.self, from: data))

        let unwrappedTrendingAll = try XCTUnwrap(trendingAll)

        // Test pagination info
        XCTAssertEqual(unwrappedTrendingAll.page, 1)
        XCTAssertEqual(unwrappedTrendingAll.totalPages, 500)
        XCTAssertEqual(unwrappedTrendingAll.totalResults, 10000)

        // Test that we have results
        XCTAssertGreaterThan(unwrappedTrendingAll.results.count, 0)

        // Test first item (movie)
        let firstItem = try XCTUnwrap(unwrappedTrendingAll.results.first)
        XCTAssertEqual(firstItem.id, 1311031)
        XCTAssertEqual(firstItem.title, "Demon Slayer: Kimetsu no Yaiba Infinity Castle")
        XCTAssertEqual(firstItem.originalTitle, "劇場版「鬼滅の刃」無限城編 第一章 猗窩座再来")
        XCTAssertEqual(firstItem.mediaType, "movie")
        XCTAssertEqual(firstItem.originalLanguage ?? "", "ja")
        XCTAssertEqual(firstItem.popularity, 387.6431, accuracy: 0.0001)
        XCTAssertEqual(firstItem.voteAverage ?? 0.0, 6.8, accuracy: 0.1)
        XCTAssertEqual(firstItem.voteCount, 5)
        XCTAssertEqual(firstItem.releaseDate, "2025-07-18")
        XCTAssertEqual(firstItem.backdropPath, "/63RnEJRNzRDvi0Fv4jhrT2eh0fl.jpg")
        XCTAssertEqual(firstItem.posterPath, "/aFRDH3P7TX61FVGpaLhKr6QiOC1.jpg")

        // Test genre IDs
        XCTAssertEqual(firstItem.genreIds, [16, 28, 14, 53])

        // Test second item (movie)
        let secondItem = try XCTUnwrap(unwrappedTrendingAll.results.dropFirst().first)
        XCTAssertEqual(secondItem.id, 1087192)
        XCTAssertEqual(secondItem.title, "How to Train Your Dragon")
        XCTAssertEqual(secondItem.originalTitle, "How to Train Your Dragon")
        XCTAssertEqual(secondItem.mediaType, "movie")
        XCTAssertEqual(secondItem.originalLanguage ?? "", "en")
        XCTAssertEqual(secondItem.popularity, 1075.8358, accuracy: 0.0001)
        XCTAssertEqual(secondItem.voteAverage ?? 0.0, 8.126, accuracy: 0.001)
        XCTAssertEqual(secondItem.voteCount, 1013)
        XCTAssertEqual(secondItem.releaseDate, "2025-06-06")

        // Test person item (4th item)
        let personItem = try XCTUnwrap(unwrappedTrendingAll.results.dropFirst(3).first)
        XCTAssertEqual(personItem.id, 1622390)
        XCTAssertEqual(personItem.name, "Lee Chae-dam")
        XCTAssertEqual(personItem.originalName, "Lee Chae-dam")
        XCTAssertEqual(personItem.mediaType, "person")
        XCTAssertEqual(personItem.gender, 1)
        XCTAssertEqual(personItem.knownForDepartment, "Acting")
        XCTAssertEqual(personItem.profilePath, "/7wMyr6F3yzvbSpu2XMxSW3vObED.jpg")
        XCTAssertEqual(personItem.popularity, 2.1793, accuracy: 0.0001)

        // Test TV show item (5th item)
        let tvShowItem = try XCTUnwrap(unwrappedTrendingAll.results.dropFirst(4).first)
        XCTAssertEqual(tvShowItem.id, 207468)
        XCTAssertEqual(tvShowItem.name, "Kaiju No. 8")
        XCTAssertEqual(tvShowItem.originalName, "怪獣８号")
        XCTAssertEqual(tvShowItem.mediaType, "tv")
        XCTAssertEqual(tvShowItem.originalLanguage ?? "", "ja")
        XCTAssertEqual(tvShowItem.popularity, 94.8197, accuracy: 0.0001)
        XCTAssertEqual(tvShowItem.voteAverage ?? 0.0, 8.6, accuracy: 0.1)
        XCTAssertEqual(tvShowItem.voteCount, 560)
        XCTAssertEqual(tvShowItem.firstAirDate, "2024-04-13")
        XCTAssertEqual(tvShowItem.originCountry, ["JP"])
    }
}