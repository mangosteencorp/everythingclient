import Swinject
@testable import TMDB_TVFeed
import XCTest

class MovieAssemblyTests: XCTestCase {
    var container: Container!

    override func setUp() {
        super.setUp()
        container = Container()
        let assembly = MovieAssembly()
        assembly.assemble(container: container)
    }

    func testDependencyRegistration() {
        // Test APIService registration
        XCTAssertNotNil(container.resolve(APIServiceProtocol.self))

        // Test Repository registration
        XCTAssertNotNil(container.resolve(MovieRepository.self))

        // Test Use Cases registration
        XCTAssertNotNil(container.resolve(FetchNowPlayingMoviesUseCase.self))
        XCTAssertNotNil(container.resolve(FetchUpcomingMoviesUseCase.self))

        // Test ViewModels registration
        XCTAssertNotNil(container.resolve(MoviesViewModel.self, name: "nowPlaying"))
        XCTAssertNotNil(container.resolve(MoviesViewModel.self, name: "upcoming"))
    }
}
