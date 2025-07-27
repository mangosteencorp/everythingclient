import XCTest
@testable import Integration_test

class DemoTestHelper {
    
    static func launchAppWithDemo(_ demoName: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["INTEGRATION_TEST_NAME"] = demoName
        app.launch()
        return app
    }
    
    static func takeScreenshot(_ app: XCUIApplication, demoName: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        
        let screenshotFolder = ".screenshots/\(timestamp)"
        let screenshotName = "\(demoName)_demo.png"
        
        // Create screenshots directory if it doesn't exist
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let screenshotsPath = "\(currentPath)/\(screenshotFolder)"
        
        do {
            try fileManager.createDirectory(atPath: screenshotsPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create screenshots directory: \(error)")
        }
        
        let screenshot = app.screenshot()
        let screenshotPath = "\(screenshotsPath)/\(screenshotName)"
        
        do {
            try screenshot.pngRepresentation.write(to: URL(fileURLWithPath: screenshotPath))
            print("Screenshot saved to: \(screenshotPath)")
        } catch {
            print("Failed to save screenshot: \(error)")
        }
    }
    
    static func verifyDemoIsShowing(_ app: XCUIApplication, expectedElements: [String]) {
        for element in expectedElements {
            XCTAssertTrue(app.staticTexts[element].exists || 
                         app.navigationBars[element].exists || 
                         app.buttons[element].exists,
                         "Expected element '\(element)' not found in demo")
        }
    }
    
    static func waitForElement(_ app: XCUIApplication, element: XCUIElement, timeout: TimeInterval = 5.0) {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTWaiter().wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - Demo-specific verification methods

extension DemoTestHelper {
    
    static func verifyTMDBFeedDemo(_ app: XCUIApplication) {
        verifyDemoIsShowing(app, expectedElements: ["Movies"])
        
        // Additional TMDB Feed specific checks
        XCTAssertTrue(app.tabBars.element.exists, "Tab bar should be visible")
        
        // Take screenshot
        takeScreenshot(app, demoName: "TMDBFeed")
    }
    
    static func verifyTMDBDiscoverDemo(_ app: XCUIApplication) {
        verifyDemoIsShowing(app, expectedElements: ["Airing Today"])
        
        // Additional TMDB Discover specific checks
        XCTAssertTrue(app.tabBars.element.exists, "Tab bar should be visible")
        
        // Take screenshot
        takeScreenshot(app, demoName: "TMDBDiscover")
    }
    
    static func verifyPokedexListDemo(_ app: XCUIApplication) {
        verifyDemoIsShowing(app, expectedElements: ["Pokédex"])
        
        // Additional Pokedex specific checks
        XCTAssertTrue(app.navigationBars["Pokédex"].exists, "Pokedex navigation bar should be visible")
        
        // Take screenshot
        takeScreenshot(app, demoName: "PokedexList")
    }
    
    static func verifyNoResultsDemo(_ app: XCUIApplication) {
        verifyDemoIsShowing(app, expectedElements: ["Show No Results"])
        
        // Additional No Results specific checks
        let showButton = app.buttons["Show No Results"]
        XCTAssertTrue(showButton.exists, "Show No Results button should be visible")
        
        // Tap the button to show the no results view
        showButton.tap()
        
        // Wait for the no results view to appear
        waitForElement(app, element: app.staticTexts["No Results Found"])
        
        // Take screenshot
        takeScreenshot(app, demoName: "NoResults")
    }
    
    static func verifyThemeSwitcherDemo(_ app: XCUIApplication) {
        verifyDemoIsShowing(app, expectedElements: ["Theme Switcher Demo"])
        
        // Additional Theme Switcher specific checks
        XCTAssertTrue(app.staticTexts["Current Theme:"].exists, "Current theme text should be visible")
        
        // Take screenshot
        takeScreenshot(app, demoName: "ThemeSwitcher")
    }
    
    static func verifyDesignSwitcherDemo(_ app: XCUIApplication) {
        verifyDemoIsShowing(app, expectedElements: ["Design Switcher Demo"])
        
        // Additional Design Switcher specific checks
        XCTAssertTrue(app.toggles["Use Fancy Design"].exists, "Design toggle should be visible")
        
        // Take screenshot
        takeScreenshot(app, demoName: "DesignSwitcher")
    }
} 