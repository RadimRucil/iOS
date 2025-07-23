import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FotoAsistentModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Nepodařilo se načíst CoreData: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Chyba při ukládání kontextu: \(error)")
            }
        }
    }
}
