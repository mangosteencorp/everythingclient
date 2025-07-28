import XCTest
@testable import Integration_test

/// Helper class for demo-specific test verification
/// Extends BaseTestCase with demo-specific verification methods
extension BaseTestCase {
    
    // MARK: - Demo-specific verification methods
    
    /// Verify TMDB Feed demo is showing correctly
    func verifyTMDBFeedDemo() {
        // Verify main elements exist
        verifyElementsExist([
            "movies_list",
            "movies_list_content"
        ])
        
        // Additional TMDB Feed specific checks
        XCTAssertTrue(app.tabBars.element.exists, "Tab bar should be visible")
        
        // Verify content type picker exists
        assertElementExists("content_type_picker")
        
        // Take screenshot
        takeScreenshot(name: "TMDBFeed_demo")
    }
    
    /// Verify TMDB Discover demo is showing correctly
    func verifyTMDBDiscoverDemo() {
        // Verify main elements exist
        verifyElementsExist([
            "discover_tab",
            "airing_today_section"
        ])
        
        // Additional TMDB Discover specific checks
        XCTAssertTrue(app.tabBars.element.exists, "Tab bar should be visible")
        
        // Take screenshot
        takeScreenshot(name: "TMDBDiscover_demo")
    }
    
    /// Verify Pokedex List demo is showing correctly
    func verifyPokedexListDemo() {
        // Verify main elements exist
        verifyElementsExist([
            "pokedex_navigation",
            "pokemon_list"
        ])
        
        // Additional Pokedex specific checks
        assertElementExists("pokedex_navigation")
        
        // Take screenshot
        takeScreenshot(name: "PokedexList_demo")
    }
    
    /// Verify Theme Switcher demo is showing correctly
    func verifyThemeSwitcherDemo() {
        // Verify main elements exist
        verifyElementsExist([
            "theme_switcher_demo",
            "current_theme_label"
        ])
        
        // Additional Theme Switcher specific checks
        assertElementExists("current_theme_label")
        
        // Take screenshot
        takeScreenshot(name: "ThemeSwitcher_demo")
    }
    
    // MARK: - Demo-specific interaction methods
    
    /// Switch content type in TMDB Feed demo
    /// - Parameter contentType: The content type to switch to ("movies" or "tvshows")
    func switchContentType(to contentType: String) {
        tapElement(withIdentifier: "content_type_picker")
        
        // Find and tap the appropriate content type option
        let contentTypeElement = app.pickerWheels.firstMatch
        if contentTypeElement.exists {
            contentTypeElement.adjust(toPickerWheelValue: contentType)
        }
    }
    
    /// Search for content in TMDB Feed demo
    /// - Parameter searchTerm: The search term to enter
    func searchForContent(_ searchTerm: String) {
        // Find the search field and enter text
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText(searchTerm)
        }
    }
    
    /// Tap on first movie in TMDB Feed demo
    func tapFirstMovie() {
        // Find the first movie cell and tap it
        let firstMovieCell = app.cells.firstMatch
        if firstMovieCell.exists {
            firstMovieCell.tap()
        }
    }
    
    // MARK: - Performance testing methods
    
    /// Measure app launch performance
    /// - Parameter demoName: Name of the demo to test
    func measureAppLaunchPerformance(for demoName: String) {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            launchApp(withDemo: demoName)
        }
    }
    
    /// Measure navigation performance
    /// - Parameter demoName: Name of the demo to test
    func measureNavigationPerformance(for demoName: String) {
        measure(metrics: [XCTClockMetric()]) {
            let app = launchAppAndWait(withDemo: demoName)
            
            // Perform navigation actions
            switch demoName {
            case "TMDBFeed":
                switchContentType(to: "tvshows")
                switchContentType(to: "movies")
            case "TMDBDiscover":
                // Add discover-specific navigation
                break
            case "PokedexList":
                tapFirstMovie()
            default:
                break
            }
        }
    }
    
    // MARK: - Accessibility testing methods
    
    /// Verify accessibility features are working
    /// - Parameter demoName: Name of the demo to test
    func verifyAccessibility(for demoName: String) {
        // Verify that all interactive elements have accessibility identifiers
        let interactiveElements = app.buttons.allElementsBoundByIndex + 
                                app.cells.allElementsBoundByIndex +
                                app.staticTexts.allElementsBoundByIndex
        
        for element in interactiveElements {
            if element.isEnabled && element.isHittable {
                XCTAssertTrue(element.identifier.isEmpty == false || 
                             element.label.isEmpty == false,
                             "Interactive element should have accessibility identifier or label")
            }
        }
    }
    
    // MARK: - Error handling methods
    
    /// Verify error states are handled properly
    /// - Parameter demoName: Name of the demo to test
    func verifyErrorHandling(for demoName: String) {
        // This would typically involve mocking network failures
        // and verifying that error states are displayed correctly
        // For now, we'll just verify that the app doesn't crash
        let app = launchAppAndWait(withDemo: demoName)
        XCTAssertTrue(app.exists, "App should still be running after launch")
    }
} 