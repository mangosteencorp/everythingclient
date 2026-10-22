@testable import CoreFeatures
import Testing
struct TMDBPersistentControllerTests {
    @Test func `initiate`() async throws {
        let _ = try await TMDBPersistentController.init(nil)
    }
}
