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

        // `.searchScopes` only renders once the search field has focus.
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()

        select("Movies", in: app, showing: "Super Movie", hiding: "Super Series")
        select("TV Shows", in: app, showing: "Super Series", hiding: "Super Movie")
        select("People", in: app, showing: "Super Star", hiding: "Super Series")
    }

    @MainActor
    private func select(
        _ scope: String,
        in app: XCUIApplication,
        showing expected: String,
        hiding forbidden: String,
        line: UInt = #line
    ) {
        let button = app.buttons[scope]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing scope \(scope)", line: line)
        button.tap()

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

    @MainActor
    private func rows(in app: XCUIApplication, startingWith prefix: String) -> XCUIElementQuery {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
    }
}
