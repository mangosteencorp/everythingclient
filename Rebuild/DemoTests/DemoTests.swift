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
