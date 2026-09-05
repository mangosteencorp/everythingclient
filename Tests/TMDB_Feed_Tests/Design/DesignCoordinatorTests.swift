import CoreFeatures
@testable import TMDB_Feed
import UIKit
import XCTest

private enum TestDesign: String, DesignVariant {
    case alpha
    case beta
    case unavailable

    static var slotTitle: String { "Test Slot" }
    static var fallback: TestDesign { .alpha }

    var displayName: String { rawValue.capitalized }

    var isAvailableOnThisDevice: Bool { self != .unavailable }
}

final class DesignCoordinatorTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "design.coordinator.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeCoordinator() -> DesignCoordinator {
        DesignCoordinator(defaults: defaults, storageKey: "selections")
    }

    func testUnsetSlotUsesFallback() {
        XCTAssertEqual(makeCoordinator().style(TestDesign.self), .alpha)
    }

    func testSelectionRoundTripsThroughStorage() {
        makeCoordinator().select(TestDesign.beta)

        // A fresh instance stands in for the next launch.
        XCTAssertEqual(makeCoordinator().style(TestDesign.self), .beta)
    }

    func testUnavailableStoredCaseFallsBack() {
        let coordinator = makeCoordinator()
        coordinator.select(TestDesign.unavailable)

        XCTAssertEqual(coordinator.style(TestDesign.self), .alpha)
    }

    func testUnknownStoredRawValueFallsBack() {
        defaults.set(["TestDesign": "caseThatWasDeleted"], forKey: "selections")

        XCTAssertEqual(makeCoordinator().style(TestDesign.self), .alpha)
    }

    func testShuffleOnlyPicksAvailableCasesAndAlwaysChanges() {
        let coordinator = makeCoordinator()
        _ = coordinator.style(TestDesign.self) // registers the slot

        for _ in 0 ..< 20 {
            let before = coordinator.style(TestDesign.self)
            coordinator.shuffleAll()
            let after = coordinator.style(TestDesign.self)

            XCTAssertNotEqual(after, before, "a shuffle must visibly change a slot with >1 option")
            XCTAssertTrue(after.isAvailableOnThisDevice)
        }
    }

    func testShuffleIgnoresSlotsNeverRead() {
        let coordinator = makeCoordinator()
        coordinator.shuffleAll()

        XCTAssertTrue(coordinator.slots.isEmpty)
        XCTAssertEqual(coordinator.style(TestDesign.self), .alpha)
    }

    func testResetClearsSelections() {
        let coordinator = makeCoordinator()
        coordinator.select(TestDesign.beta)
        coordinator.resetToDefaults()

        XCTAssertEqual(coordinator.style(TestDesign.self), .alpha)
    }

    func testRegisteredSlotExposesOnlyAvailableOptions() throws {
        let coordinator = makeCoordinator()
        _ = coordinator.style(TestDesign.self)

        let slot = try XCTUnwrap(coordinator.slots.first)
        XCTAssertEqual(slot.title, "Test Slot")
        XCTAssertEqual(slot.options.map(\.rawValue), ["alpha", "beta"])
    }

    func testTypeErasedSelectIgnoresUnregisteredSlots() {
        let coordinator = makeCoordinator()
        coordinator.select(slotKey: "TestDesign", rawValue: "beta")

        XCTAssertEqual(coordinator.style(TestDesign.self), .alpha, "nothing registered that slot yet")
    }

    func testFeedTabDesignNeverOffersABottomBarOnIPhone() throws {
        // The app shell owns the bottom edge on iPhone; a second bottom bar inside it is unusable.
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone)

        XCTAssertFalse(FeedTabDesign.availableCases.contains(.systemTabs))
        XCTAssertTrue(FeedTabDesign.availableCases.contains(.topSegments))
    }

    #if targetEnvironment(macCatalyst)
    func testCatalystFallsBackFromStoredSystemTabs() {
        let coordinator = makeCoordinator()
        coordinator.select(FeedTabDesign.systemTabs)

        XCTAssertEqual(coordinator.style(FeedTabDesign.self), .topSegments)
        XCTAssertEqual(FeedTabDesign.availableCases, [.topSegments])
    }
    #endif
}
