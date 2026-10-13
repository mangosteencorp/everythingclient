import CoreData
import Foundation

public final class TVBookMarkEntity: NSManagedObject {
    @NSManaged public var tv_id: Int32
    @NSManaged public var created: Date
}

