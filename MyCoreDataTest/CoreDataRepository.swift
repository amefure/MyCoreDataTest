//
//  CoreDataRepository.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import CoreData
//
//class CoreDataRepository {
//    
//    /// ファイル名
//    private static let persistentName = "MyCoreDataTest"
//    
//    ///
//    private static var persistenceController: NSPersistentContainer = {
//        let container = NSPersistentContainer(name: CoreDataRepository.persistentName)
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//        container.viewContext.automaticallyMergesChangesFromParent = true
//        return container
//    }()
//    
//    private static var context: NSManagedObjectContext {
//        return CoreDataRepository.persistenceController.viewContext
//    }
//    
//    private static var contextBG: NSManagedObjectContext {
//        return CoreDataRepository.persistenceController.newBackgroundContext()
//    }
//}
//
//
//extension CoreDataRepository {
//    
//    /// 新規作成
//    static func entity<T: NSManagedObject>() -> T {
//        let entityDescription = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
//        return T(entity: entityDescription, insertInto: nil)
//    }
//    
//    /// 取得処理
//    static func fetch<T: NSManagedObject>() -> [T] {
//        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
//
//        do {
//            return try context.fetch(fetchRequest)
//        } catch let error as NSError {
//          print("Could not fetch. \(error), \(error.userInfo)")
//            return []
//        }
//    }
//    
//    /// 取得処理
////    static func fetch<T: NSManagedObject>(completion: @escaping ([T]) -> Void) {
////        contextBG.perform {
////            let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
////            do {
////                let result =  try contextBG.fetch(fetchRequest)
////                completion(result)
////            } catch let error as NSError {
////                print("Could not fetch. \(error), \(error.userInfo)")
////                completion([])
////            }
////        }
////        
////    }
//    
//    
//    /// 新規作成
//    static func newEntity<T: NSManagedObject>() -> T {
//        let entity = NSEntityDescription.insertNewObject(forEntityName: String(describing: T.self), into: context)
//        return entity as! T
//    }
//    
//    /// 新規作成
//    static func newLocator() -> Person {
//        let entity = NSEntityDescription.insertNewObject(forEntityName: String(describing: Person.self), into: context)
//        return entity as! Person
//    }
//
//    
//    /// 追加処理
//    static func insert(_ object: NSManagedObject) {
//        context.insert(object)
//    }
//    
//    /// 削除処理
//    static func delete(_ object: NSManagedObject) {
//        context.delete(object)
//    }
//    /// 保存処理
//    static func save() {
//        // 変更がある場合のみ
//        guard context.hasChanges else { return }
//        do {
//            try context.save()
//        } catch let error as NSError {
//            fatalError("Unresolved error \(error), \(error.userInfo)")
//        }
//    }
//}


//class CoreDataRepository2 {
//    static let shared = CoreDataRepository2()
//    
//    
//    private var persistenceController: NSPersistentContainer = {
//        let container = NSPersistentContainer(name: "MyCoreDataTest")
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//        container.viewContext.automaticallyMergesChangesFromParent = true
//        return container
//    }()
//    
//    
//    /// 新規作成
//    func newEntity<T: NSManagedObject>() -> T {
//        var context = persistenceController.viewContext
//        let entity = NSEntityDescription.insertNewObject(forEntityName: String(describing: T.self), into: context)
//        return entity as! T
//    }
//    
//    /// 新規作成
//    func newLocator() -> Person {
//        var context = persistenceController.viewContext
//        let entity = NSEntityDescription.insertNewObject(forEntityName: String(describing: Person.self), into: context)
//        return entity as! Person
//    }
//    
//    
//    /// 追加処理
//    func insert(_ object: NSManagedObject) {
//        var context = persistenceController.viewContext
//        context.insert(object)
//        guard context.hasChanges else { return }
//        do {
//            try context.save()
//        } catch let error as NSError {
//            fatalError("Unresolved error \(error), \(error.userInfo)")
//        }
//    }
//    
//
//    /// 取得処理
//    func fetch<T: NSManagedObject>() -> [T] {
//        var context = persistenceController.viewContext
//        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
//
//        do {
//            return try context.fetch(fetchRequest)
//        } catch let error as NSError {
//          print("Could not fetch. \(error), \(error.userInfo)")
//            return []
//        }
//    }
//}




class CoreDataRepository2 {
    static let shared = CoreDataRepository2()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyCoreDataTest")
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
    func newEntity<T: NSManagedObject>(onBackgroundThread: Bool = false, completion: @escaping (T) -> Void) {
        let context = onBackgroundThread ? makeBackgroundContext() : persistentContainer.viewContext
        context.perform {
            let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
            let newObject = T(entity: entity, insertInto: context)
            completion(newObject)
        }
    }
    
    /// 追加処理
    func insert(_ object: NSManagedObject, onBackgroundThread: Bool = false) {
        print((object as? Company)?.id)
        print((object as? Company)?.name)
        let context = onBackgroundThread ? object.managedObjectContext ?? makeBackgroundContext() : persistentContainer.viewContext
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
    func fetch<T: NSManagedObject>(onBackgroundThread: Bool = false, completion: @escaping ([T]) -> Void) {
        let context = onBackgroundThread ? makeBackgroundContext() : persistentContainer.viewContext
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
