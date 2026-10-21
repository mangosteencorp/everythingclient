@testable import CoreFeatures
import Testing
import Foundation
import CoreData
struct TVBookmarkEntityTest {
    let container: NSPersistentContainer
    init() async throws {
        let controller = try await TMDBPersistentController()
        container = controller.container
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        container.persistentStoreDescriptions = [description]
    }

    @Test func `test insert & fetch bookmark`() async throws {
        let model = container.managedObjectModel
        let entity = model.entitiesByName["TVBookmarkEntity"]
        print(entity?.managedObjectClassName as Any)   // today: GlenMovies_CoreFeatures.TVBookmarkEntity
        print(NSStringFromClass(TVBookmarkEntity.self)) // CoreFeatures.TVBookmarkEntity
        let tvID = Int32.random(in: 1...Int32.max)
        let created = Date()
        let writerContext = container.viewContext
        let newBookmark = TVBookmarkEntity(context: writerContext)
        newBookmark.tv_id = tvID
        newBookmark.created = created
        try writerContext.save()
        let reader = container.viewContext
        let request = TVBookmarkEntity.fetchRequest()
        let savedEntities = try reader.fetch(request)
        #expect(savedEntities.count == 1)
        #expect(savedEntities[0].tv_id == tvID)
        #expect(savedEntities[0].created == created)
    }

}
