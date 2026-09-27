import XCTest

/// Search is a root tab of every app shell, not only of the sectioned sidebar.
///
/// Each test opens the tab view on one shell — picked through the design store's argument
/// domain, so a saved choice cannot leak in — then opens Search and expects the search page with
/// its field. Runs on iPhone and iPad; the sidebar tab bar only exists on iPad.
final class TMDBSearchTabTests: XCTestCase {
    @MainActor
    func testBottomTabBarHasSearchTab() {
        let app = launch(shell: "bottomTabBar")
        openSearchTab(in: app, shell: "bottomTabBar")
    }

    @MainActor
    func testFloatingTabBarHasSearchTab() {
        let app = launch(shell: "floatingTabBar")
        openSearchTab(in: app, shell: "floatingTabBar")
    }

    @MainActor
    func testSidebarTabBarHasSearchTab() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "The sidebar tab bar is iPad-only")
        let app = launch(shell: "sidebarTabBar")
        openSearchTab(in: app, shell: "sidebarTabBar")
    }

    /// On iPhone the sectioned shell has six tabs — three roots, the two feed sections and Search
    /// — and a compact bar holds five, so Search lands behind "More".
    @MainActor
    func testSectionedSidebarHasSearchTab() {
        let app = launch(shell: "sectionedSidebar")
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            return openSearchTab(in: app, shell: "sectionedSidebar")
        }
        let more = app.tabBars.buttons["More"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "sectionedSidebar no longer overflows into More")
        capture(app, "sectionedSidebar_01_launch")

        more.tap()
        let searchRow = app.cells.staticTexts["Search"]
        XCTAssertTrue(searchRow.waitForExistence(timeout: 5), "sectionedSidebar has no Search tab")
        capture(app, "sectionedSidebar_02_more")
        searchRow.tap()

        let page = app.descendants(matching: .any)["feed_search_page"].firstMatch
        XCTAssertTrue(page.waitForExistence(timeout: 10), "sectionedSidebar did not open the search page")
        capture(app, "sectionedSidebar_03_search")
        // Strict: once the field shows up this fails, so whoever fixes it drops the expectation.
        XCTExpectFailure("Pushed from the More list, the search page gets no search field")
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5), "sectionedSidebar shows no search field")
    }

    /// Paged tabs have no bar to tap: Search is the last page.
    @MainActor
    func testPagedTabsEndOnSearchPage() {
        let app = launch(shell: "pagedTabs")
        let indicator = app.pageIndicators.firstMatch
        XCTAssertTrue(indicator.waitForExistence(timeout: 15), "Paged tabs lost their page indicator")
        XCTAssertEqual(indicator.value as? String, "page 1 of 5")
        capture(app, "pagedTabs_01_launch")

        // Tapping the trailing end of a page indicator advances one page.
        for _ in 0..<4 {
            indicator.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        }
        XCTAssertEqual(indicator.value as? String, "page 5 of 5")
        assertSearchPage(in: app, shell: "pagedTabs")
    }

    // MARK: - Helpers

    @MainActor
    private func launch(shell: String) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["INTEGRATION_TEST_NAME"] = "TMDBTabsSavedShell"
        app.launchArguments += [
            "--uitesting", "-AppleLanguages", "(en)",
            "-design_coordinator_selections", "{ AppShellDesign = \(shell); }",
        ]
        app.launch()
        addTeardownBlock { app.terminate() }
        return app
    }

    @MainActor
    private func openSearchTab(in app: XCUIApplication, shell: String) {
        let searchTab = app.buttons["tab.search"]
        XCTAssertTrue(searchTab.waitForExistence(timeout: 15), "\(shell) has no Search tab")
        capture(app, "\(shell)_01_launch")

        searchTab.tap()
        assertSearchPage(in: app, shell: shell)
    }

    @MainActor
    private func assertSearchPage(in app: XCUIApplication, shell: String) {
        let page = app.descendants(matching: .any)["feed_search_page"].firstMatch
        XCTAssertTrue(page.waitForExistence(timeout: 10), "\(shell) did not open the search page")
        // A missing field means the shell hosts the page without a navigation container, or (iOS
        // 26+ system tab bars) without search-tab activation.
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "\(shell) shows no search field")
        // System bars make room for the field themselves; nothing does that for the floating bar.
        if shell == "floatingTabBar" {
            XCTAssertFalse(field.frame.intersects(app.buttons["tab.search"].frame), "The floating bar covers the field")
        }
        capture(app, "\(shell)_02_search")
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
