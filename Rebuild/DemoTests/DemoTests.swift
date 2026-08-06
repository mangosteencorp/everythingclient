//
//  DemoTests.swift
//  DemoTests
//
//  Created by Quang on 2025-07-25.
//

import XCTest
@testable import Integration_test
@testable import TMDB_Feed
@testable import TMDB_Discover
@testable import Pokedex_Pokelist
@testable import Shared_UI_Support

final class DemoTests: BaseTestCase {

    // MARK: - TMDB Feed Tests
    
    @MainActor
    func testTMDBFeedDemoLaunch() throws {
        // Given & When
        launchAppAndWait(withDemo: "TMDBFeed")
        
        // Then
        verifyTMDBFeedDemo()
    }

    @MainActor
    func testTMDBFeedMoreOnTheAirShowsResults() throws {
        verifyHiddenTVFeed("On the Air")
    }

    @MainActor
    func testTMDBFeedMoreAiringTodayShowsResults() throws {
        verifyHiddenTVFeed("Airing Today")
    }

    private func verifyHiddenTVFeed(_ feedTitle: String, file: StaticString = #filePath, line: UInt = #line) {
        launchAppAndWait(withDemo: "TMDBFeed", timeout: 30)

        let moreButton = app.tabBars.buttons["More"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 15), "The More tab was not found", file: file, line: line)
        moreButton.tap()

        let menuItem = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", feedTitle))
            .firstMatch
        XCTAssertTrue(menuItem.waitForExistence(timeout: 10), "The More menu item '\(feedTitle)' was not found", file: file, line: line)
        menuItem.tap()

        let content = app.descendants(matching: .any)["tvshows_list_content"]
        XCTAssertTrue(content.waitForExistence(timeout: 20), "TV feed content did not appear for '\(feedTitle)'", file: file, line: line)

        let tvShowRows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "tvshowlist1.tvshowrow"))
            .firstMatch
        if !tvShowRows.waitForExistence(timeout: 30) {
            takeScreenshot(name: "TMDBFeed_\(feedTitle.replacingOccurrences(of: " ", with: "_"))_failure")
            print("TMDB Feed UI hierarchy for '\(feedTitle)':\n\(app.debugDescription)")
            XCTFail("No TV show rows appeared for '\(feedTitle)'", file: file, line: line)
        }
    }
    
    // MARK: - TMDB Discover Tests
    
    @MainActor
    func testTMDBDiscoverDemoLaunch() throws {
        // Given & When
        launchAppAndWait(withDemo: "TMDBDiscover")
        
        // Then
        verifyTMDBDiscoverDemo()
    }

    @MainActor
    func testSettingsLaunchSwiftfinFlow() throws {
        launchAppAndWait(withDemo: "TMDBSettings")
        verifyTMDBSettingsDemo()
        let launchSwiftfinIdentifier = "settings.launchSwiftfin.button"
        let launchSFbutton = app.descendants(matching: .button).matching(identifier: launchSwiftfinIdentifier).firstMatch
        launchSFbutton.tap()
        waitForElement(withIdentifier: "swiftfin.close.button")

        tapElement(withIdentifier: "swiftfin.close.button")
        waitForElement(withIdentifier: "settings.page")
    }

    @MainActor
    func testPersonFilmographyDesignSwitch() throws {
        launchAppAndWait(withDemo: "TMDBPersonDetail", timeout: 20)
        verifyTMDBPersonDetailDemo()

        tapElement(withIdentifier: "personDetail.switchDesign.button")
        waitForElement(withIdentifier: "personDetail.filmography.carousel")

        tapElement(withIdentifier: "personDetail.switchDesign.button")
        waitForElement(withIdentifier: "personDetail.filmography.list")
    }

    @MainActor
    func testMovieDetailOSTSectionVisible() throws {
        launchAppAndWait(withDemo: "TMDBMovieDetail", timeout: 20)
        verifyTMDBMovieDetailDemo()
        waitForElement(withIdentifier: "movieDetail.ost.section", timeout: 20)
    }
    
    // MARK: - Pokedex Tests
    
    @MainActor
    func testPokedexListDemoLaunch() throws {
        // Given & When
        launchAppAndWait(withDemo: "PokedexList")
        
        // Then
        verifyPokedexListDemo()
    }
    
    @MainActor
    func testPokedexListDemoNavigation() throws {
        // Given
        launchAppAndWait(withDemo: "PokedexList")
        
        // When
        tapFirstMovie() // This will tap the first Pokemon cell
        
        // Then
        // Verify navigation occurred
        XCTAssertTrue(app.navigationBars.element.exists, "Navigation should have occurred")
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testTMDBFeedLaunchPerformance() throws {
        measureAppLaunchPerformance(for: "TMDBFeed")
    }
    
    @MainActor
    func testTMDBDiscoverLaunchPerformance() throws {
        measureAppLaunchPerformance(for: "TMDBDiscover")
    }
    
    @MainActor
    func testPokedexListLaunchPerformance() throws {
        measureAppLaunchPerformance(for: "PokedexList")
    }
    
}
