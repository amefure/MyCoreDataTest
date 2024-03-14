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
    
    /// メインスレッドで使用するContext
    private func makeContext() -> NSManagedObjectContext {
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    /// バックグラウンドスレッドで使用するContext
    private func makeBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    /// 新規作成
    public func newEntity<T: NSManagedObject>(onBackgroundThread: Bool = false, completion: @escaping (T) -> Void) {
        let context = onBackgroundThread ? makeBackgroundContext() : makeContext()
        context.perform {
            let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
            let newObject = T(entity: entity, insertInto: nil)
            completion(newObject)
        }
    }
    
    public func entity<T: NSManagedObject>(onBackgroundThread: Bool = false) -> T {
        let context = onBackgroundThread ? makeBackgroundContext() : makeContext()
        print("---------------entity",Thread.current)
        var result: T!
        context.performAndWait {
            let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
            result = T(entity: entity, insertInto: context)
        }
        return result
    }
    
    /// 追加処理
    public func insert(_ object: NSManagedObject, onBackgroundThread: Bool = false) {
        let context = onBackgroundThread ? makeBackgroundContext() : makeContext()
        saveContext(context)
    }
    
    /// 更新処理
    public func update(onBackgroundThread: Bool = false) {
        let context = onBackgroundThread ? makeBackgroundContext() : makeContext()
        saveContext(context)
    }
    
    /// 削除処理
    public func delete(_ object: NSManagedObject, onBackgroundThread: Bool = false) {
        let context = onBackgroundThread ? object.managedObjectContext ?? makeBackgroundContext() : makeContext()
        context.delete(object)
        saveContext(context)
    }
    
    /// Contextに応じたSave
    private func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
            
        } catch let error as NSError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }

    /// 取得処理：fetchはContextを切り分ける必要がない？
    public func fetch<T: NSManagedObject>(completion: @escaping ([T]) -> Void) {
        let context = makeContext()
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
    
    
//    public func fetch<T: NSManagedObject>() -> [T] {
//        let context = makeContext()
//        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
//        var result: [T] = []
//        context.performAndWait {
//            do {
//                let fetchedObjects = try context.fetch(fetchRequest)
//                result = fetchedObjects
//            } catch let error as NSError {
//                print("Could not fetch. \(error), \(error.userInfo)")
//                
//            }
//        }
//        return result
//    }
//

    
    public func fetch<T: NSManagedObject>() -> [T] {
        let context = makeContext()
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        var result: [T] = []
        
        let group = DispatchGroup()
        group.enter()
        context.perform {
            defer {
                group.leave()
            }
            
            do {
                let fetchedObjects = try context.fetch(fetchRequest)
                result = fetchedObjects
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
        group.wait()
        
        return result
    }

    
    
    
    /// 取得処理：fetchはContextを切り分ける必要がない？
    public func fetchSingle<T: NSManagedObject>(predicate: NSPredicate? = nil, sorts: [NSSortDescriptor]? = nil, completion: @escaping (T?) -> Void) {
        let context = makeContext()
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))

        context.perform {
            // フィルタリング
            if let predicate = predicate {
                fetchRequest.predicate = predicate
            }
            
            // ソート
            if let sorts = sorts {
                fetchRequest.sortDescriptors = sorts
            }
            
            do {
                let entitys = try context.fetch(fetchRequest)
                if let entity = entitys.first {
                    completion(entity)
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
                completion(nil)
            }
            completion(nil)
        }
    }
    
    
    
            
}
