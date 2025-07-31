import XCTest
@testable import Integration_test

/// Base test case for all demo UI tests
/// Provides common setup, teardown, and helper methods
class BaseTestCase: XCTestCase {
    
    // MARK: - Properties
    
    var app: XCUIApplication!
    var currentDemo: String = ""
    
    // MARK: - Test Lifecycle
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Stop immediately when a failure occurs
        continueAfterFailure = false
        
        // Initialize app
        app = XCUIApplication()
        
        // Set up default launch arguments
        setupLaunchArguments()
    }
    
    override func tearDownWithError() throws {
        // Take screenshot on failure
        if let failure = testRun?.failureCount, failure > 0 {
            takeScreenshot(name: "\(currentDemo)_failure")
        }
        
        // Clean up
        app = nil
        currentDemo = ""
        
        try super.tearDownWithError()
    }
    
    // MARK: - Setup Methods
    
    private func setupLaunchArguments() {
        // Add any common launch arguments here
        app.launchArguments.append("--uitesting")
    }
    
    // MARK: - App Launch Methods
    
    /// Launch app with specific demo
    /// - Parameter demoName: Name of the demo to launch
    /// - Returns: The launched XCUIApplication
    @discardableResult
    func launchApp(withDemo demoName: String) -> XCUIApplication {
        currentDemo = demoName
        app.launchEnvironment["INTEGRATION_TEST_NAME"] = demoName
        app.launch()
        return app
    }
    
    /// Launch app with demo and wait for it to be ready
    /// - Parameters:
    ///   - demoName: Name of the demo to launch
    ///   - timeout: Timeout for waiting (default: 10 seconds)
    /// - Returns: The launched XCUIApplication
    @discardableResult
    func launchAppAndWait(withDemo demoName: String, timeout: TimeInterval = 10.0) -> XCUIApplication {
        let app = launchApp(withDemo: demoName)
        waitForAppToBeReady(timeout: timeout)
        return app
    }
    
    // MARK: - Wait Methods
    
    /// Wait for app to be ready (no loading indicators)
    /// - Parameter timeout: Timeout for waiting
    func waitForAppToBeReady(timeout: TimeInterval = 10.0) {
        // Wait for any loading indicators to disappear
        let loadingPredicate = NSPredicate(format: "exists == false")
        let loadingExpectation = XCTNSPredicateExpectation(
            predicate: loadingPredicate,
            object: app.activityIndicators.firstMatch
        )
        
        XCTWaiter().wait(for: [loadingExpectation], timeout: timeout)
    }
    
    /// Wait for element to exist
    /// - Parameters:
    ///   - element: The element to wait for
    ///   - timeout: Timeout for waiting (default: 5 seconds)
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5.0) {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTWaiter().wait(for: [expectation], timeout: timeout)
    }
    
    /// Wait for element with accessibility identifier
    /// - Parameters:
    ///   - identifier: Accessibility identifier
    ///   - timeout: Timeout for waiting (default: 5 seconds)
    /// - Returns: The found element
    @discardableResult
    func waitForElement(withIdentifier identifier: String, timeout: TimeInterval = 5.0) -> XCUIElement {
        let element = findElement(withIdentifier: identifier)
        waitForElement(element, timeout: timeout)
        return element
    }
    
    // MARK: - Element Finding Methods
    
    /// Find element with accessibility identifier
    /// - Parameter identifier: Accessibility identifier
    /// - Returns: The found element
    func findElement(withIdentifier identifier: String) -> XCUIElement {
        return app.otherElements[identifier] ?? 
               app.staticTexts[identifier] ?? 
               app.buttons[identifier] ?? 
               app.navigationBars[identifier] ?? 
               app.tabBars[identifier] ??
               app.collectionViews[identifier] ??
               app.tables[identifier]
    }
    
    /// Find all elements with accessibility identifier
    /// - Parameter identifier: Accessibility identifier
    /// - Returns: Array of found elements
    func findAllElements(withIdentifier identifier: String) -> [XCUIElement] {
        var elements: [XCUIElement] = []
        
        // Check different element types
        let elementTypes: [XCUIElementQuery] = [
            app.otherElements,
            app.staticTexts,
            app.buttons,
            app.navigationBars,
            app.tabBars,
            app.collectionViews,
            app.tables
        ]
        
        for elementType in elementTypes {
            let matchingElements = elementType.matching(identifier: identifier)
            if matchingElements.count > 0 {
                elements.append(contentsOf: matchingElements.allElementsBoundByIndex)
            }
        }
        
        return elements
    }
    
    // MARK: - Verification Methods
    
    /// Verify that specific elements exist
    /// - Parameters:
    ///   - identifiers: Array of accessibility identifiers to verify
    ///   - timeout: Timeout for waiting (default: 5 seconds)
    func verifyElementsExist(_ identifiers: [String], timeout: TimeInterval = 5.0) {
        for identifier in identifiers {
            let element = findElement(withIdentifier: identifier)
            waitForElement(element, timeout: timeout)
            XCTAssertTrue(element.exists, "Expected element with identifier '\(identifier)' not found")
        }
    }
    
    /// Verify that specific elements don't exist
    /// - Parameters:
    ///   - identifiers: Array of accessibility identifiers to verify
    ///   - timeout: Timeout for waiting (default: 5 seconds)
    func verifyElementsDoNotExist(_ identifiers: [String], timeout: TimeInterval = 5.0) {
        for identifier in identifiers {
            let element = findElement(withIdentifier: identifier)
            let predicate = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
            XCTWaiter().wait(for: [expectation], timeout: timeout)
            XCTAssertFalse(element.exists, "Element with identifier '\(identifier)' should not exist")
        }
    }
    
    // MARK: - Screenshot Methods
    
    /// Take screenshot with timestamp
    /// - Parameter name: Name for the screenshot
    func takeScreenshot(name: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        
        // Use the Documents directory for saving screenshots
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to access Documents directory")
            return
        }
        
        let screenshotFolder = documentsURL.appendingPathComponent("UITesting-screenshots/\(timestamp)")
        let screenshotName = "\(name).png"
        let screenshotPath = screenshotFolder.appendingPathComponent(screenshotName)
        
        // Create screenshots directory if it doesn't exist
        do {
            try fileManager.createDirectory(at: screenshotFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create screenshots directory: \(error)")
            return
        }
        
        let screenshot = app.screenshot()
        
        do {
            try screenshot.pngRepresentation.write(to: screenshotPath)
            print("Screenshot saved to: \(screenshotPath.path)")
        } catch {
            print("Failed to save screenshot: \(error)")
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Tap element with accessibility identifier
    /// - Parameter identifier: Accessibility identifier
    func tapElement(withIdentifier identifier: String) {
        let element = findElement(withIdentifier: identifier)
        waitForElement(element)
        element.tap()
    }
    
    /// Tap element and wait for navigation
    /// - Parameters:
    ///   - identifier: Accessibility identifier
    ///   - expectedElement: Expected element to appear after navigation
    func tapElementAndWaitForNavigation(withIdentifier identifier: String, expectedElement: String) {
        tapElement(withIdentifier: identifier)
        waitForElement(withIdentifier: expectedElement)
    }
    
    // MARK: - Text Input Methods
    
    /// Type text into element with accessibility identifier
    /// - Parameters:
    ///   - identifier: Accessibility identifier
    ///   - text: Text to type
    func typeText(_ text: String, intoElementWithIdentifier identifier: String) {
        let element = findElement(withIdentifier: identifier)
        waitForElement(element)
        element.tap()
        element.typeText(text)
    }
    
    // MARK: - Assertion Helpers
    
    /// Assert that element exists
    /// - Parameter identifier: Accessibility identifier
    func assertElementExists(_ identifier: String) {
        let element = findElement(withIdentifier: identifier)
        XCTAssertTrue(element.exists, "Element with identifier '\(identifier)' should exist")
    }
    
    /// Assert that element doesn't exist
    /// - Parameter identifier: Accessibility identifier
    func assertElementDoesNotExist(_ identifier: String) {
        let element = findElement(withIdentifier: identifier)
        XCTAssertFalse(element.exists, "Element with identifier '\(identifier)' should not exist")
    }
    
    /// Assert that element is enabled
    /// - Parameter identifier: Accessibility identifier
    func assertElementIsEnabled(_ identifier: String) {
        let element = findElement(withIdentifier: identifier)
        XCTAssertTrue(element.isEnabled, "Element with identifier '\(identifier)' should be enabled")
    }
    
    /// Assert that element is disabled
    /// - Parameter identifier: Accessibility identifier
    func assertElementIsDisabled(_ identifier: String) {
        let element = findElement(withIdentifier: identifier)
        XCTAssertFalse(element.isEnabled, "Element with identifier '\(identifier)' should be disabled")
    }
} 
