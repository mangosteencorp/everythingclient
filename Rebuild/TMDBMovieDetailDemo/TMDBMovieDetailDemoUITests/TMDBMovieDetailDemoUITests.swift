//
//  TMDBMovieDetailDemoUITests.swift
//  TMDBMovieDetailDemoUITests
//
//  Created by Quinn Haus on 2026-10-13.
//

import XCTest

final class TMDBMovieDetailDemoUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testJellyfinPlayAndOpenActions() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["jellyfinSection"].tap()

        let play = app.buttons["movieDetail.jellyfin.play.button"]
        let open = app.buttons["movieDetail.jellyfin.open.button"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        XCTAssertTrue(open.exists)
        XCTAssertEqual(play.frame.midY, open.frame.midY, accuracy: 2)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Jellyfin Play and Open actions"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        if open.isEnabled {
            open.tap()
            let closeDetails = app.buttons["jellyfin.details.close.button"]
            XCTAssertTrue(closeDetails.waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["jellyfin.player.close.button"].exists)
            closeDetails.tap()
        } else {
            XCTAssertTrue(app.staticTexts["Opening movie pages in Swiftfin is unavailable in this build."].exists)
        }

        XCTAssertTrue(play.waitForExistence(timeout: 5))
        play.tap()
        XCTAssertTrue(app.buttons["jellyfin.player.close.button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["jellyfin.details.close.button"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
