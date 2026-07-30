//
//  DemoTestsLaunchTests.swift
//  DemoTests
//
//  Created by Quang on 2025-07-25.
//

import XCTest
import Integration_test

final class DemoTestsLaunchTests: BaseTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    @MainActor
    func testLaunch() throws {
        // Given & When
        let app = launchAppAndWait(withDemo: "TMDBFeed")
        
        // Then
        // Verify basic app functionality
        XCTAssertTrue(app.exists, "App should be running")
        XCTAssertTrue(app.state == .runningForeground, "App should be in foreground")
        
        // Take screenshot for launch verification
        takeScreenshot(name: "Launch_Screen")
        
        // Verify that the app doesn't crash during launch
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // Measure launch performance across different configurations
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            launchApp(withDemo: "TMDBFeed")
        }
    }
    
    @MainActor
    func testLaunchWithDifferentDemos() throws {
        for demo in IntegrationTestLauncher.DemoTest.allCases {
            let app = launchApp(withDemo: demo.rawValue)
            let previewRoot = app.descendants(matching: .any)[demo.accessibilityIdentifier]

            XCTAssertTrue(
                previewRoot.waitForExistence(timeout: 20),
                "Preview route did not become visible: \(demo.rawValue)"
            )
            XCTAssertEqual(app.state, .runningForeground, "App should be in foreground for \(demo.rawValue)")

            takeScreenshot(name: "Launch_\(demo.rawValue)")
            app.terminate()
        }
    }
    
    @MainActor
    func testLaunchStability() throws {
        // Test multiple launches to ensure stability
        for i in 1...3 {
            // Given & When
            let app = launchAppAndWait(withDemo: "TMDBFeed")
            
            // Then
            XCTAssertTrue(app.exists, "App should launch successfully on attempt \(i)")
            
            // Terminate app for next iteration
            app.terminate()
        }
    }
}
