import Swinject
@testable import TMDB_Discover
import XCTest

class MovieAssemblyTests: XCTestCase {
    var container: Container!

    override func setUp() {
        super.setUp()
        container = Container()
        let assembly = DiscoverAssembly(apiKey: "test_api_key")
        assembly.assemble(container: container)
    }

    func testDependencyRegistration() {
        // Test APIService registration
        XCTAssertNotNil(container.resolve(APIServiceProtocol.self))

        // Test Repository registration
        XCTAssertNotNil(container.resolve(DiscoverRepository.self))

        // Test Use Cases registration
        XCTAssertNotNil(container.resolve(FetchDiscoverMoviesUseCase.self))
        XCTAssertNotNil(container.resolve(FetchGenresUseCase.self))
        XCTAssertNotNil(container.resolve(FetchTVGenresUseCase.self))
    }
}
