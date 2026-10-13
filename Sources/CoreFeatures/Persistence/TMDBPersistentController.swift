import CoreData

public final class TMDBPersistentController {
    public let container: NSPersistentContainer
    init() {
        self.container =  NSPersistentContainer(name: "Model")
        container.loadPersistentStores {_, error in
            if let error {
                // TODO: analytics tracker 
            }
        }
    }
}
