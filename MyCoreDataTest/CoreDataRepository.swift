//
//  CoreDataRepository.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import CoreData

class CoreDataRepository {
    
    static let shared = CoreDataRepository()
    
    private static let persistentName = "MyCoreDataTest"
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: CoreDataRepository.persistentName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    private func makeBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    /// 新規作成
    public func newEntity<T: NSManagedObject>(onBackgroundThread: Bool = false, completion: @escaping (T) -> Void) {
        let context = onBackgroundThread ? makeBackgroundContext() : persistentContainer.viewContext
        context.perform {
            let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
            let newObject = T(entity: entity, insertInto: nil)
            completion(newObject)
        }
    }
    
    /// 追加処理
    public func insert(_ object: NSManagedObject, onBackgroundThread: Bool = false) {
        let context = onBackgroundThread ? object.managedObjectContext ?? makeBackgroundContext() : persistentContainer.viewContext
        context.insert(object)
        saveContext(context)
    }
    
    /// 削除処理
    public func delete(_ object: NSManagedObject, onBackgroundThread: Bool = false) {
        let context = onBackgroundThread ? object.managedObjectContext ?? makeBackgroundContext() : persistentContainer.viewContext
        context.delete(object)
        saveContext(context)
    }
    
    private func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
            
        } catch let error as NSError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }

    /// 取得処理
    public func fetch<T: NSManagedObject>(completion: @escaping ([T]) -> Void) {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))

        context.perform {
            do {
                let fetchedObjects = try context.fetch(fetchRequest)
                completion(fetchedObjects)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
                completion([])
            }
        }
    }

}
