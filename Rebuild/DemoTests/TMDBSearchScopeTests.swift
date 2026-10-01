import XCTest

/// The scope picker and the rows have to agree.
///
/// The stub behind the search demo names every row after its scope — "Super Movie", "Super
/// Series", "Super Star" — so a scope switch that requests the scope the user just left shows up
/// here as the previous scope's rows still on screen.
final class TMDBSearchScopeTests: XCTestCase {
    @MainActor
    func testSwitchingScopeShowsTheSelectedScopesResults() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["INTEGRATION_TEST_NAME"] = "TMDBSearch"
        app.launchArguments += ["--uitesting", "-AppleLanguages", "(en)"]
        app.launch()
        defer { app.terminate() }

        // The demo opens on All with "super" already searched, so movies, series and people are
        // all interleaved on screen.
        XCTAssertTrue(rows(in: app, startingWith: "Super Movie").firstMatch.waitForExistence(timeout: 30))
        XCTAssertTrue(rows(in: app, startingWith: "Super Series").firstMatch.exists)
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))

        // The scope bar is always on screen — no need to focus the field first, which is all
        // `.searchScopes` offered.
        select("movies", in: app, showing: "Super Movie", hiding: "Super Series")
        select("tvShows", in: app, showing: "Super Series", hiding: "Super Movie")
        select("people", in: app, showing: "Super Star", hiding: "Super Series")
        // The last three sit past the trailing edge of an iPhone-wide bar.
        select("keywords", in: app, showing: "Super Theme", hiding: "Super Star")
    }

    @MainActor
    private func select(
        _ scope: String,
        in app: XCUIApplication,
        showing expected: String,
        hiding forbidden: String,
        line: UInt = #line
    ) {
        let button = app.buttons["search_scope_\(scope)"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing scope \(scope)", line: line)
        // `isHittable` throws for a button scrolled out of the bar, so check the frame instead.
        for _ in 0..<3 where !app.frame.contains(CGPoint(x: button.frame.midX, y: button.frame.midY)) {
            app.descendants(matching: .any)["search_scope_bar"].firstMatch.swipeLeft()
        }
        button.tap()
        XCTAssertTrue(button.isSelected, "\(scope) did not become the selected scope", line: line)

        XCTAssertTrue(
            rows(in: app, startingWith: expected).firstMatch.waitForExistence(timeout: 10),
            "\(scope) never showed its own rows", line: line
        )
        let gone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count == 0"), object: rows(in: app, startingWith: forbidden)
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [gone], timeout: 5), .completed,
            "\(scope) is still showing \(forbidden) rows", line: line
        )
    }

    /// Each row is one accessibility element whose label starts with its title.
    @MainActor
    private func rows(in app: XCUIApplication, startingWith prefix: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
    }
}
