@testable import TMDB_Shared_Backend
import XCTest

final class WatchProviderModelsTests: XCTestCase {
    func testWatchProviderResponseDecoding() throws {
        // Given
        let jsonData = try loadJSONData(from: "mov_provider")

        // When
        let watchProviderResponse = try JSONDecoder().decode(WatchProviderResponse.self, from: jsonData)

        // Then
        XCTAssertEqual(watchProviderResponse.id, 615457)
        XCTAssertFalse(watchProviderResponse.results.isEmpty)

        // Test specific regions
        XCTAssertNotNil(watchProviderResponse.results["US"])
        XCTAssertNotNil(watchProviderResponse.results["CA"])
        XCTAssertNotNil(watchProviderResponse.results["GB"])
    }

    func testWatchProviderRegionDecoding() throws {
        // Given
        let jsonData = try loadJSONData(from: "mov_provider")
        let watchProviderResponse = try JSONDecoder().decode(WatchProviderResponse.self, from: jsonData)

        // When
        guard let usRegion = watchProviderResponse.results["US"] else {
            XCTFail("US region should exist")
            return
        }

        // Then
        XCTAssertTrue(usRegion.link.contains("themoviedb.org"))
        XCTAssertTrue(usRegion.link.contains("615457"))
        XCTAssertTrue(usRegion.link.contains("locale=US"))

        // Test that we have some providers
        XCTAssertNotNil(usRegion.buy)
        XCTAssertNotNil(usRegion.rent)
        XCTAssertNotNil(usRegion.flatrate)
    }

    func testWatchProviderDecoding() throws {
        // Given
        let jsonData = try loadJSONData(from: "mov_provider")
        let watchProviderResponse = try JSONDecoder().decode(WatchProviderResponse.self, from: jsonData)

        // When
        guard let usRegion = watchProviderResponse.results["US"],
              let buyProviders = usRegion.buy,
              let firstProvider = buyProviders.first else {
            XCTFail("Should have buy providers in US region")
            return
        }

        // Then
        XCTAssertGreaterThan(firstProvider.id, 0)
        XCTAssertFalse(firstProvider.providerName.isEmpty)
        XCTAssertGreaterThanOrEqual(firstProvider.displayPriority, 0)

        // Test logo URL generation
        if let logoPath = firstProvider.logoPath {
            XCTAssertTrue(firstProvider.logoURL?.contains("image.tmdb.org") == true)
            XCTAssertTrue(firstProvider.logoURL?.contains(logoPath) == true)
        }
    }

    func testDifferentProviderTypes() throws {
        // Given
        let jsonData = try loadJSONData(from: "mov_provider")
        let watchProviderResponse = try JSONDecoder().decode(WatchProviderResponse.self, from: jsonData)

        // When & Then - Test different regions have different provider types
        for (regionCode, regionData) in watchProviderResponse.results {
            print("Testing region: \(regionCode)")

            // At least one provider type should exist
            let hasProviders = (regionData.buy?.isEmpty == false) ||
                             (regionData.rent?.isEmpty == false) ||
                             (regionData.flatrate?.isEmpty == false) ||
                             (regionData.free?.isEmpty == false) ||
                             (regionData.ads?.isEmpty == false)

            XCTAssertTrue(hasProviders, "Region \(regionCode) should have at least one provider type")
        }
    }

    func testRegionCodeParsing() throws {
        // Given
        let jsonData = try loadJSONData(from: "mov_provider")
        let watchProviderResponse = try JSONDecoder().decode(WatchProviderResponse.self, from: jsonData)

        // When & Then
        for regionCode in watchProviderResponse.results.keys {
            // Region codes should be 2-letter country codes
            XCTAssertEqual(regionCode.count, 2, "Region code should be 2 characters: \(regionCode)")
            XCTAssertTrue(regionCode.allSatisfy { $0.isUppercase }, "Region code should be uppercase: \(regionCode)")
        }
    }

    // Helper method to load JSON data from test resources
    private func loadJSONData(from filename: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: filename, withExtension: "json") else {
            throw NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Could not find \(filename).json"])
        }
        return try Data(contentsOf: url)
    }
}