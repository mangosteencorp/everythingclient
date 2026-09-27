import XCTest

/// Every query parameter TMDB's search endpoints take is a chip — and only on the scopes whose
/// endpoint takes it.
///
/// Runs the stub-backed `TMDBSearch` demo, which opens on All with "super" searched. Its rows
/// are dated 2024 unless a year filter the scope sends is set, in which case they carry that
/// year: a filter change that did not search again shows up as rows still dated 2024.
final class TMDBSearchFilterTests: XCTestCase {
    private let chipsByScope: KeyValuePairs<String, [String]> = [
        "multi": ["include_adult", "language"],
        "movies": ["include_adult", "language", "primary_release_year", "region", "year"],
        "tvShows": ["include_adult", "language", "first_air_date_year", "year"],
        "people": ["include_adult", "language"],
        "collections": ["include_adult", "language", "region"],
        "companies": [],
        "keywords": [],
    ]

    @MainActor
    func testEachScopeOffersTheChipsItsEndpointTakes() {
        let app = launchDemo()

        for (scope, expected) in chipsByScope {
            select(scope, in: app)
            let ids = chipIDs(in: app, matching: expected)
            XCTAssertEqual(ids, expected, "\(scope) offers the wrong chips")
            capture(app, "chips_\(scope)")
        }
    }

    @MainActor
    func testSettingAYearRelabelsTheChipAndSearchesAgain() {
        let app = launchDemo()
        select("movies", in: app)
        XCTAssertTrue(rows(in: app, "Super Movie", dated: "2024").firstMatch.waitForExistence(timeout: 10))

        let chip = app.buttons["search_filter_chip_primary_release_year"]
        pick("2021", for: chip, in: app)

        XCTAssertTrue(wait(for: chip, label: "Release Year: 2021"), "The chip does not show the year")
        XCTAssertTrue(
            rows(in: app, "Super Movie", dated: "2021").firstMatch.waitForExistence(timeout: 10),
            "Setting the year did not search again"
        )
        capture(app, "01_release_year_2021")

        // TV has no release year: the value is kept but not sent, and "Clear All" has nothing
        // on screen to clear.
        select("tvShows", in: app)
        XCTAssertTrue(rows(in: app, "Super Series", dated: "2024").firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["search_filter_clear_all"].exists)
        capture(app, "02_tv_ignores_release_year")

        select("movies", in: app)
        XCTAssertTrue(wait(for: chip, label: "Release Year: 2021"), "Switching scopes lost the year")
        XCTAssertTrue(rows(in: app, "Super Movie", dated: "2021").firstMatch.waitForExistence(timeout: 10))

        app.buttons["search_filter_clear_all"].tap()
        XCTAssertTrue(wait(for: chip, label: "Release Year"), "Clear All left the chip set")
        XCTAssertTrue(
            rows(in: app, "Super Movie", dated: "2024").firstMatch.waitForExistence(timeout: 10),
            "Clearing did not search again"
        )
        XCTAssertFalse(app.buttons["search_filter_clear_all"].exists)
        capture(app, "03_cleared")
    }

    @MainActor
    func testFirstAirYearCancelAndRemove() {
        let app = launchDemo()
        select("tvShows", in: app)

        let firstAired = app.buttons["search_filter_chip_first_air_date_year"]
        pick("2019", for: firstAired, in: app)
        XCTAssertTrue(wait(for: firstAired, label: "First Air Year: 2019"))
        XCTAssertTrue(
            rows(in: app, "Super Series", dated: "2019").firstMatch.waitForExistence(timeout: 10),
            "The first air year was not sent"
        )
        capture(app, "01_first_air_year_2019")

        // Cancel leaves the filter as it was.
        let language = app.buttons["search_filter_chip_language"]
        language.tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "French")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(wait(for: language, label: "Language"), "Cancel applied the language")

        pick("French", for: language, in: app)
        XCTAssertTrue(wait(for: language, label: "Language: French"), "The chip shows a code, not a name")
        capture(app, "02_language_french")

        // The x on an active chip clears just that chip.
        let remove = app.buttons["search_filter_remove_first_air_date_year"]
        reveal(remove, in: app)
        remove.tap()
        XCTAssertTrue(wait(for: firstAired, label: "First Air Year"))
        XCTAssertTrue(language.label == "Language: French")
        XCTAssertTrue(rows(in: app, "Super Series", dated: "2024").firstMatch.waitForExistence(timeout: 10))
        capture(app, "03_first_air_year_removed")
    }

    // MARK: - Helpers

    @MainActor
    private func launchDemo() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["INTEGRATION_TEST_NAME"] = "TMDBSearch"
        app.launchArguments += ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        addTeardownBlock { app.terminate() }
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 30), "The demo shows no search field")
        return app
    }

    @MainActor
    private func select(_ scope: String, in app: XCUIApplication, line: UInt = #line) {
        let button = app.buttons["search_scope_\(scope)"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing scope \(scope)", line: line)
        let bar = app.descendants(matching: .any)["search_scope_bar"].firstMatch
        for _ in 0..<3 where !app.frame.contains(CGPoint(x: button.frame.midX, y: button.frame.midY)) {
            if button.frame.minX < app.frame.midX {
                bar.swipeRight()
            } else {
                bar.swipeLeft()
            }
        }
        button.tap()
        XCTAssertTrue(button.isSelected, "\(scope) did not become the selected scope", line: line)
    }

    /// The chips on screen, once the row has settled on the expected set.
    @MainActor
    private func chipIDs(in app: XCUIApplication, matching expected: [String]) -> [String] {
        let chips = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'search_filter_chip_'"))
        let ids = { chips.allElementsBoundByIndex.map { $0.identifier.replacingOccurrences(of: "search_filter_chip_", with: "") } }
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in ids() == expected }, object: nil)
        _ = XCTWaiter.wait(for: [settled], timeout: 5)
        return ids()
    }

    /// Opens a chip's picker, spins the wheel to `value` and applies it.
    @MainActor
    private func pick(_ value: String, for chip: XCUIElement, in app: XCUIApplication, line: UInt = #line) {
        XCTAssertTrue(chip.waitForExistence(timeout: 5), "Missing chip", line: line)
        reveal(chip, in: app)
        chip.tap()
        let wheel = app.pickerWheels.firstMatch
        XCTAssertTrue(wheel.waitForExistence(timeout: 5), "The chip opened no picker", line: line)
        wheel.adjust(toPickerWheelValue: value)
        capture(app, "picker_\(value)")
        app.buttons["search_filter_done"].tap()
    }

    /// Scrolls the chip row until `element` is wholly on screen.
    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<3 where !app.frame.contains(CGPoint(x: element.frame.maxX, y: element.frame.midY)) {
            app.descendants(matching: .any)["search_filter_bar"].firstMatch.swipeLeft()
        }
    }

    @MainActor
    private func wait(for element: XCUIElement, label: String) -> Bool {
        let relabelled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: element)
        return XCTWaiter.wait(for: [relabelled], timeout: 5) == .completed
    }

    /// Rows are one accessibility element each: "Super Movie 1, Movie, 2024, …".
    @MainActor
    private func rows(in app: XCUIApplication, _ prefix: String, dated year: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", prefix, ", \(year),")
        )
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
