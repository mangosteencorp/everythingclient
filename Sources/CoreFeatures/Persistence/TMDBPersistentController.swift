import CoreData

public final class TMDBPersistentController {
    public let container: NSPersistentContainer
    nonisolated(unsafe) private static let model = NSManagedObjectModel.mergedModel(from: [.module])!
    public let tracker: AnalyticsTracker?
    public private(set) var storeDescription: NSPersistentStoreDescription? = nil
    public init(_ tracker: AnalyticsTracker? = nil) async throws {
        container = NSPersistentContainer(name: "Model", managedObjectModel: Self.model)
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

    public init(_ tracker: AnalyticsTracker? = nil) {
        container = NSPersistentContainer(name: "Model", managedObjectModel: Self.model)
        self.tracker = tracker
        container.loadPersistentStores { [weak self] desc, error in
            if let error {
                assertionFailure(error.localizedDescription)
                tracker?.trackError(err: error)
            } else {
                self?.storeDescription = desc
            }
        }
    }
}
