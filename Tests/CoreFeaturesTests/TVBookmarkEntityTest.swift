import CoreData
@testable import CoreFeatures
import Foundation
import Testing
@MainActor // viewContext belongs to the main queue
struct TVBookmarkEntityTest {
    let container: NSPersistentContainer
    init() async throws {
        let controller = try await TMDBPersistentController()
        container = controller.container
        // The controller has already loaded the on-disk store; swap it for an in-memory one so each test starts empty
        let coordinator = container.persistentStoreCoordinator
        try coordinator.persistentStores.forEach(coordinator.remove)
        _ = try coordinator.addPersistentStore(type: .inMemory, at: URL(fileURLWithPath: "/dev/null"))
    }

    @Test func `test insert & fetch bookmark`() async throws {
        let entity = try #require(container.managedObjectModel.entitiesByName["TVBookmarkEntity"])
        // Fail here instead of crashing in TVBookmarkEntity(context:) when the model's class name drifts
        try #require(entity.managedObjectClassName == NSStringFromClass(TVBookmarkEntity.self))
        let tvID = Int32.random(in: 1...Int32.max)
        let created = Date()
        let writerContext = container.viewContext
        let newBookmark = TVBookmarkEntity(context: writerContext)
        newBookmark.tvId = tvID
        newBookmark.created = created
        try writerContext.save()
        let reader = container.viewContext
        let request = TVBookmarkEntity.fetchRequest()
        let savedEntities = try reader.fetch(request)
        try #require(savedEntities.count == 1)
        #expect(savedEntities[0].tvId == tvID)
        #expect(savedEntities[0].created == created)
    }
}
