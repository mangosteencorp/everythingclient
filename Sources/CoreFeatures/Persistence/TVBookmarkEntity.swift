import CoreData
import Foundation

public final class TVBookmarkEntity: NSManagedObject {
    @NSManaged public var tv_id: Int32
    @NSManaged public var created: Date

    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<TVBookmarkEntity> {
        NSFetchRequest<TVBookmarkEntity>(entityName: "TVBookmarkEntity")
    }
}
