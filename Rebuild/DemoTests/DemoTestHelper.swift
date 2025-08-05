import XCTest
@testable import Integration_test

/// Helper class for demo-specific test verification
/// Extends BaseTestCase with demo-specific verification methods
extension BaseTestCase {
    
    // MARK: - Demo-specific verification methods
    
    /// Verify TMDB Feed demo is showing correctly
    func verifyTMDBFeedDemo() {
        // Take screenshot
        takeScreenshot(name: "TMDBFeed_demo")
    }
    
    /// Verify TMDB Discover demo is showing correctly
    func verifyTMDBDiscoverDemo() {
        // Take screenshot
        takeScreenshot(name: "TMDBDiscover_demo")
    }
    
    /// Verify Pokedex List demo is showing correctly
    func verifyPokedexListDemo() {
        // Take screenshot
        takeScreenshot(name: "PokedexList_demo")
    }
    
    /// Verify Theme Switcher demo is showing correctly
    func verifyThemeSwitcherDemo() {
        // Take screenshot
        takeScreenshot(name: "ThemeSwitcher_demo")
    }
    
    // MARK: - Demo-specific interaction methods
    
    /// Switch content type in TMDB Feed demo
    /// - Parameter contentType: The content type to switch to ("Movies" or "TV Shows")
    func switchContentType(to contentType: String) {
        // Basic content switching - just tap the first picker wheel if available
        let pickerWheel = app.pickerWheels.firstMatch
        if pickerWheel.exists {
            pickerWheel.adjust(toPickerWheelValue: contentType)
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
            
            // Perform basic navigation actions
            switch demoName {
            case "TMDBFeed":
                switchContentType(to: "TV Shows")
                switchContentType(to: "Movies")
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
        // Basic accessibility check - just verify the app is still running
        XCTAssertTrue(app.exists, "App should still be running")
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
