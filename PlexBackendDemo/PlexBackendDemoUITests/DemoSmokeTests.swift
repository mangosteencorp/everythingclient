import XCTest

/// No-login smoke tests. `--fixtures` loads the synthetic sample server.
final class DemoSmokeTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor func testSampleHomeOpensDetailsAndDownloadPlan() {
        let app = launch()
        XCTAssertTrue(app.descendants(matching: .any)["plex.continueWatching"].waitForExistence(timeout: 10))
        let movie = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "The Sample Movie")).firstMatch
        XCTAssertTrue(movie.waitForExistence(timeout: 10))
        activate(movie)
        XCTAssertTrue(app.buttons["plex.play"].waitForExistence(timeout: 10))
        attach(app, name: "Sample movie details")
        let download = app.buttons["plex.download"]
        scrollTo(download, in: app)
        activate(download)
        XCTAssertTrue(app.descendants(matching: .any)["plex.plannedFiles"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["plex.startDownload"].isEnabled)
        attach(app, name: "Sample download plan")
    }

    @MainActor func testLibraryBrowsesItemsAndCollections() {
        let app = launch()
        selectTab("Library", in: app)
        let movies = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Movies")).firstMatch
        XCTAssertTrue(movies.waitForExistence(timeout: 10))
        activate(movies)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Second Feature")).firstMatch.waitForExistence(timeout: 10))
        app.descendants(matching: .any)["plex.sectionMode"].buttons["Collections"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Sample Collection")).firstMatch.waitForExistence(timeout: 10))
        attach(app, name: "Sample collections")
    }

    @MainActor func testOfflineModeKeepsOpenedContentAndShowsBanner() {
        let app = launch()
        XCTAssertTrue(app.descendants(matching: .any)["plex.continueWatching"].waitForExistence(timeout: 10))
        selectTab("Account", in: app)
        let offline = app.switches["plex.offlineMode"]
        XCTAssertTrue(offline.waitForExistence(timeout: 10))
        // Tap the switch itself; the row's center can land on the label.
        let control = offline.switches.firstMatch
        (control.exists ? control : offline).tap()
        XCTAssertTrue(app.descendants(matching: .any)["plex.offlineBanner"].waitForExistence(timeout: 5))
        selectTab("Home", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["plex.continueWatching"].waitForExistence(timeout: 10))
        attach(app, name: "Offline home from cache")
        selectTab("Downloads", in: app)
        XCTAssertTrue(app.staticTexts["No downloads yet"].waitForExistence(timeout: 5))
    }

    @MainActor func testSignedOutAccountOffersSignInAndAdvancedSetup() {
        let app = launch()
        selectTab("Account", in: app)
        XCTAssertTrue(app.buttons["plex.signIn"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["plex.advancedConnection"].exists)
        let samples = app.buttons["plex.samples"]
        scrollTo(samples, in: app)
        XCTAssertTrue(samples.exists && app.switches["plex.curlLogging"].exists)
        attach(app, name: "Account")
    }

    @MainActor private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--fixtures"]
        app.launch()
        return app
    }

    @MainActor private func activate(_ element: XCUIElement) {
#if os(macOS)
        element.click()
#else
        element.tap()
#endif
    }

    @MainActor private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
#if !os(macOS)
        for _ in 0..<6 where !(element.exists && element.isHittable) { app.swipeUp() }
#endif
    }

    @MainActor private func selectTab(_ title: String, in app: XCUIApplication) {
#if os(macOS)
        app.radioButtons[title].click()
#else
        let tab = app.tabBars.buttons[title]
        if tab.waitForExistence(timeout: 5) {
            tab.tap()
        } else {
            app.buttons[title].firstMatch.tap()
        }
#endif
    }

    @MainActor private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
