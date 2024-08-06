import XCTest
@testable import TMDB_Dimilian_clean

class AppContainerTests: XCTestCase {

    func testSharedInstance() {
        let instance1 = AppContainer.shared
        let instance2 = AppContainer.shared
        XCTAssert(instance1 === instance2, "AppContainer.shared should return the same instance.")
    }

    func testDependencyResolution() {
        let apiService = AppContainer.shared.container.resolve(APIService.self)
        XCTAssertNotNil(apiService, "APIService should be resolvable.")
        // Add similar assertions for each type of dependency...
    }
}
