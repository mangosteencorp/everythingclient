//
//  DemoTestsLaunchTests.swift
//  DemoTests
//
//  Created by Quang on 2025-07-25.
//

import XCTest

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
        // Test launch with different demo configurations
        let demos = ["TMDBFeed", "TMDBDiscover", "PokedexList", "ThemeSwitcher"]
        
        for demo in demos {
            // Given & When
            let app = launchAppAndWait(withDemo: demo)
            
            // Then
            XCTAssertTrue(app.exists, "App should launch successfully with demo: \(demo)")
            XCTAssertTrue(app.state == .runningForeground, "App should be in foreground with demo: \(demo)")
            
            // Take screenshot for each demo
            takeScreenshot(name: "Launch_\(demo)")
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
