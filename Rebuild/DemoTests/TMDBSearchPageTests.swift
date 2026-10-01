import XCTest

/// The search page around the results: what it offers before a query, remembering queries,
/// opening a hit and paging further.
///
/// Runs the stub-backed `TMDBSearch` demo: it opens on All with "super" searched, keeps recent
/// searches in memory seeded with "Dune", "Christopher Nolan" and "Breaking Bad", and pushes a
/// page titled after whichever row was tapped.
final class TMDBSearchPageTests: XCTestCase {
    @MainActor
    func testSubmittedQueryBecomesARecentSearch() {
        let app = launchDemo()
        let field = app.searchFields.firstMatch

        // Clearing the query swaps the results for the idle page and its recents.
        clear(field)
        let idle = app.descendants(matching: .any)["search_idle"].firstMatch
        XCTAssertTrue(idle.waitForExistence(timeout: 5), "No idle page once the query was cleared")
        XCTAssertTrue(recent("Dune", in: app).exists, "The seeded recent searches are missing")
        XCTAssertTrue(app.descendants(matching: .any)["search_trending"].firstMatch.exists, "No trending row")
        capture(app, "01_idle")

        // Clearing keeps the keyboard up on iPhone but not on iPad.
        field.tap()
        field.typeText("batman\n")
        XCTAssertTrue(rows(in: app, startingWith: "Batman Movie").firstMatch.waitForExistence(timeout: 10))
        capture(app, "02_batman_results")

        clear(field)
        let batman = recent("batman", in: app)
        XCTAssertTrue(batman.waitForExistence(timeout: 5), "The submitted query was not remembered")
        XCTAssertLessThan(batman.frame.minY, recent("Dune", in: app).frame.minY, "The newest search is not first")
        capture(app, "03_recents")

        // A recent search runs again when tapped.
        recent("Dune", in: app).tap()
        XCTAssertTrue(rows(in: app, startingWith: "Dune Movie").firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(field.value as? String, "Dune")
        capture(app, "04_recent_rerun")
    }

    @MainActor
    func testTappingAResultOpensItAndBackKeepsTheResults() {
        let app = launchDemo()
        let row = rows(in: app, startingWith: "Super Movie 13").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 30))

        row.tap()
        let detail = app.staticTexts["search.demo.detail"]
        XCTAssertTrue(detail.waitForExistence(timeout: 5), "Tapping a result did not open it")
        XCTAssertEqual(detail.label, "Super Movie 13")
        capture(app, "01_detail")

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5), "The results were gone after coming back")
    }

    @MainActor
    func testScrollingToTheEndLoadsTheNextPage() {
        let app = launchDemo()
        let results = app.descendants(matching: .any)["search_results"].firstMatch
        XCTAssertTrue(rows(in: app, startingWith: "Super Movie 13").firstMatch.waitForExistence(timeout: 30))

        // Page one ends at row 24; the first row of page two is "Super Movie 25".
        let nextPage = rows(in: app, startingWith: "Super Movie 25").firstMatch
        for _ in 0..<8 where !nextPage.exists {
            results.swipeUp()
        }
        XCTAssertTrue(nextPage.waitForExistence(timeout: 5), "The second page never loaded")
        capture(app, "01_second_page")
    }

    // MARK: - Helpers

    @MainActor
    private func launchDemo() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["INTEGRATION_TEST_NAME"] = "TMDBSearch"
        app.launchArguments += ["--uitesting", "-AppleLanguages", "(en)"]
        app.launch()
        addTeardownBlock { app.terminate() }
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 30), "The demo shows no search field")
        return app
    }

    @MainActor
    private func clear(_ field: XCUIElement) {
        field.tap()
        let clearButton = field.buttons["Clear text"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        clearButton.tap()
    }

    @MainActor
    private func recent(_ query: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(identifier: "search_recent").matching(NSPredicate(format: "label == %@", query)).firstMatch
    }

    /// Each row is one accessibility element whose label starts with its title.
    @MainActor
    private func rows(in app: XCUIApplication, startingWith prefix: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
