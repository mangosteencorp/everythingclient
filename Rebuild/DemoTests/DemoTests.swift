//
//  DemoTests.swift
//  DemoTests
//
//  Created by Quang on 2025-07-25.
//

import XCTest
@testable import Integration_test
@testable import TMDB_Feed
@testable import TMDB_Discover
@testable import Pokedex_Pokelist
@testable import Shared_UI_Support

final class DemoTests: XCTestCase {

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
    func testTMDBFeedDemo() throws {
        let app = DemoTestHelper.launchAppWithDemo("TMDBFeed")
        DemoTestHelper.verifyTMDBFeedDemo(app)
    }

    @MainActor
    func testTMDBDiscoverDemo() throws {
        let app = DemoTestHelper.launchAppWithDemo("TMDBDiscover")
        DemoTestHelper.verifyTMDBDiscoverDemo(app)
    }

    @MainActor
    func testPokedexListDemo() throws {
        let app = DemoTestHelper.launchAppWithDemo("PokedexList")
        DemoTestHelper.verifyPokedexListDemo(app)
    }

    @MainActor
    func testNoResultsDemo() throws {
        let app = DemoTestHelper.launchAppWithDemo("NoResults")
        DemoTestHelper.verifyNoResultsDemo(app)
    }

    @MainActor
    func testThemeSwitcherDemo() throws {
        let app = DemoTestHelper.launchAppWithDemo("ThemeSwitcher")
        DemoTestHelper.verifyThemeSwitcherDemo(app)
    }

    @MainActor
    func testDesignSwitcherDemo() throws {
        let app = DemoTestHelper.launchAppWithDemo("DesignSwitcher")
        DemoTestHelper.verifyDesignSwitcherDemo(app)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
