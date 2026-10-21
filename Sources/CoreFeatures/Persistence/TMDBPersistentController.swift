import CoreData

public final class TMDBPersistentController {
    public let container: NSPersistentContainer
    nonisolated(unsafe) private static let model = NSManagedObjectModel.mergedModel(from: [.module])!
    public let tracker: AnalyticsTracker?
    public init(_ tracker: AnalyticsTracker? = nil) async throws {
        self.container = NSPersistentContainer(name: "Model", managedObjectModel: Self.model)
        self.tracker = tracker
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
