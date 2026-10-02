import XCTest

/// On the iPhone Duo the system puts the navigation bar's buttons in a rail beside the camera, and
/// only a page that spans the window reaches it. Paged Tabs kept its pages inside the safe area, so
/// the feed's shuffle button and a detail page's back button stayed at the top of the page; both are
/// measured in the bottom tab bar shell first, as the reference. Discover and Profile, which are
/// UIKit pages, stopped short of the rail in every shell.
///
/// Run it on the iPhone Duo and on a compact iPhone such as the iPhone 18 Pro Max.
final class TMDBPagedShellRailTests: XCTestCase {
    @MainActor
    func testPagedShellLaysOutPagesLikeTheTabBarShell() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += [
            "--uitesting", "-AppleLanguages", "(en)",
            "-design_coordinator_selections",
            "{ AppNavigationDesign = plain; FeedContentDesign = grid; FeedEmptyStateDesign = plain; }",
        ]
        app.launch()
        addTeardownBlock { app.terminate() }

        // The app root seeds the bottom tab bar, the reference for where everything belongs.
        let tabBar = measure(app, shell: "bottomTabBar")
        tapTab(in: app, identifier: "tab.movieFeed", label: "Movies")

        let shuffle = app.buttons["design.shuffle.button"]
        XCTAssertTrue(shuffle.waitForExistence(timeout: 10), "No design shuffle button")
        shuffle.press(forDuration: 1)
        app.buttons["App Shell"].tap()
        app.buttons["Paged Tabs"].tap()
        XCTAssertTrue(app.pageIndicators.firstMatch.waitForExistence(timeout: 10), "Paged Tabs did not open")
        let paged = measure(app, shell: "pagedTabs")

        continueAfterFailure = true
        for (spot, expected) in tabBar.sorted(by: { $0.key < $1.key }) {
            let actual = paged[spot] ?? .null
            let message = "\(spot): paged \(actual) vs tab bar \(expected)"
            XCTAssertEqual(actual.midX, expected.midX, accuracy: 1, message)
            XCTAssertEqual(actual.midY, expected.midY, accuracy: 1, message)
            XCTAssertEqual(actual.width, expected.width, accuracy: 1, message)
        }
    }

    /// Frames of the spots that must not depend on the shell, with a screenshot of each page.
    /// Starts and ends on the feed's root.
    @MainActor
    private func measure(_ app: XCUIApplication, shell: String) -> [String: CGRect] {
        var frames: [String: CGRect] = [:]

        let shuffle = app.buttons["design.shuffle.button"]
        XCTAssertTrue(shuffle.waitForExistence(timeout: 15), "\(shell): no design shuffle button")
        frames["shuffle button"] = shuffle.frame
        attachScreenshot(of: app, named: "\(shell)_feed")

        let movie = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'movielist1.movierow'")).firstMatch
        XCTAssertTrue(movie.waitForExistence(timeout: 15), "\(shell): no movie in the feed")
        movie.tap()
        let back = app.buttons["BackButton"]
        XCTAssertTrue(back.waitForExistence(timeout: 10), "\(shell): the movie detail has no back button")
        frames["detail back button"] = back.frame
        attachScreenshot(of: app, named: "\(shell)_detail")
        back.tap()
        XCTAssertTrue(shuffle.waitForExistence(timeout: 10), "\(shell): back did not return to the feed")

        // Discover and Profile are UIKit pages: their backgrounds reach every edge, under the rail too.
        let window = app.windows.firstMatch.frame
        turnPage(in: app, shell: shell, to: "tab.marketplace", label: "Discover")
        XCTAssertTrue(app.staticTexts["Movie Genres"].waitForExistence(timeout: 15), "\(shell): Discover did not load")
        attachScreenshot(of: app, named: "\(shell)_discover")
        XCTAssertEqual(innermostList(in: app, containing: "Movie Genres")?.frame, window, "\(shell): Discover")

        turnPage(in: app, shell: shell, to: "tab.profile", label: "Profile")
        // Signed out, Profile has no list to measure.
        if app.staticTexts["Watchlist"].waitForExistence(timeout: 15) {
            attachScreenshot(of: app, named: "\(shell)_profile")
            let profile = innermostList(in: app, containing: "Watchlist")?.frame ?? .null
            XCTAssertEqual(profile.minX, window.minX, "\(shell): Profile \(profile) in \(window)")
            XCTAssertEqual(profile.width, window.width, "\(shell): Profile \(profile) in \(window)")
        }

        print("\(shell) frames: \(frames)")
        return frames
    }

    /// The page's own list: a paging container around it contains the same rows, so it comes first.
    @MainActor
    private func innermostList(in app: XCUIApplication, containing label: String) -> XCUIElement? {
        app.collectionViews.containing(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex.last
    }

    @MainActor
    private func turnPage(in app: XCUIApplication, shell: String, to identifier: String, label: String) {
        guard shell == "pagedTabs" else {
            tapTab(in: app, identifier: identifier, label: label)
            return
        }
        // Tapping right of the current dot turns one page forward.
        let dots = app.pageIndicators.firstMatch
        XCTAssertTrue(dots.waitForExistence(timeout: 5), "No page dots")
        dots.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
    }

    @MainActor
    private func tapTab(in app: XCUIApplication, identifier: String, label: String) {
        // The system tab bar sometimes exposes its buttons without their identifiers.
        let tab = app.buttons.matching(NSPredicate(format: "identifier == %@ OR label == %@", identifier, label))
            .firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "No \(label) tab")
        tab.tap()
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
