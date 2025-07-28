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
    func testTMDBFeedDemoContentSwitching() throws {
        // Given
        launchAppAndWait(withDemo: "TMDBFeed")
        
        // When & Then - Switch to TV Shows
        switchContentType(to: "TV Shows")
        verifyElementsExist(["tvshows_list_content"])
        
        // When & Then - Switch back to Movies
        switchContentType(to: "Movies")
        verifyElementsExist(["movies_list_content"])
    }
    
    @MainActor
    func testTMDBFeedDemoSearch() throws {
        // Given
        launchAppAndWait(withDemo: "TMDBFeed")
        
        // When
        searchForContent("test")
        
        // Then
        // Verify search field is active
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists, "Search field should be visible")
    }
    
    @MainActor
    func testTMDBFeedDemoNavigation() throws {
        // Given
        launchAppAndWait(withDemo: "TMDBFeed")
        
        // When
        tapFirstMovie()
        
        // Then
        // Verify navigation occurred (this would depend on your detail view accessibility identifiers)
        XCTAssertTrue(app.navigationBars.element.exists, "Navigation should have occurred")
    }
    
    // MARK: - TMDB Discover Tests
    
    @MainActor
    func testTMDBDiscoverDemoLaunch() throws {
        // Given & When
        launchAppAndWait(withDemo: "TMDBDiscover")
        
        // Then
        verifyTMDBDiscoverDemo()
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
    
    // MARK: - Theme Switcher Tests
    
    @MainActor
    func testThemeSwitcherDemoLaunch() throws {
        // Given & When
        launchAppAndWait(withDemo: "ThemeSwitcher")
        
        // Then
        verifyThemeSwitcherDemo()
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
    
    @MainActor
    func testThemeSwitcherLaunchPerformance() throws {
        measureAppLaunchPerformance(for: "ThemeSwitcher")
    }
    
    // MARK: - Navigation Performance Tests
    
    @MainActor
    func testTMDBFeedNavigationPerformance() throws {
        measureNavigationPerformance(for: "TMDBFeed")
    }
    
    @MainActor
    func testPokedexListNavigationPerformance() throws {
        measureNavigationPerformance(for: "PokedexList")
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testTMDBFeedAccessibility() throws {
        // Given
        launchAppAndWait(withDemo: "TMDBFeed")
        
        // When & Then
        verifyAccessibility(for: "TMDBFeed")
    }
    
    @MainActor
    func testTMDBDiscoverAccessibility() throws {
        // Given
        launchAppAndWait(withDemo: "TMDBDiscover")
        
        // When & Then
        verifyAccessibility(for: "TMDBDiscover")
    }
    
    @MainActor
    func testPokedexListAccessibility() throws {
        // Given
        launchAppAndWait(withDemo: "PokedexList")
        
        // When & Then
        verifyAccessibility(for: "PokedexList")
    }
    
    @MainActor
    func testThemeSwitcherAccessibility() throws {
        // Given
        launchAppAndWait(withDemo: "ThemeSwitcher")
        
        // When & Then
        verifyAccessibility(for: "ThemeSwitcher")
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testTMDBFeedErrorHandling() throws {
        verifyErrorHandling(for: "TMDBFeed")
    }
    
    @MainActor
    func testTMDBDiscoverErrorHandling() throws {
        verifyErrorHandling(for: "TMDBDiscover")
    }
    
    @MainActor
    func testPokedexListErrorHandling() throws {
        verifyErrorHandling(for: "PokedexList")
    }
    
    @MainActor
    func testThemeSwitcherErrorHandling() throws {
        verifyErrorHandling(for: "ThemeSwitcher")
    }
}
