import CoreFeatures
@testable import TMDB
import UIKit
import XCTest

@MainActor
final class FeedTabDesignTests: XCTestCase {
    func testNeverOffersABottomBarOnIPhone() throws {
        // The app shell owns the bottom edge on iPhone; a second bottom bar inside it is unusable.
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone)

        XCTAssertFalse(FeedTabDesign.availableCases.contains(.systemTabs))
        XCTAssertTrue(FeedTabDesign.availableCases.contains(.topSegments))
    }

    #if targetEnvironment(macCatalyst)
    func testCatalystFallsBackFromStoredSystemTabs() throws {
        let suiteName = "feed.tab.design.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let coordinator = DesignCoordinator(defaults: defaults, storageKey: "selections")
        coordinator.select(FeedTabDesign.systemTabs)

        XCTAssertEqual(coordinator.style(FeedTabDesign.self), .topSegments)
        XCTAssertEqual(FeedTabDesign.availableCases, [.topSegments])
    }
    #endif
}
