//
//  MainCoreDaraRepository.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/03/15.
//

import UIKit
import CoreData


class MainCoreDataRepository {
    
    static let shared = MainCoreDataRepository()
    
    private static let persistentName = "MyCoreDataTest"
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: MainCoreDataRepository.persistentName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private var viewContext: NSManagedObjectContext {
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }

}

// MARK: - Create
extension MainCoreDataRepository {
    
    /// 新規作成
    public func newEntity<T: NSManagedObject>() -> T {
        let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: viewContext)!
        return T(entity: entity, insertInto: viewContext)
    }
}

// MARK: - Insert/Update/Delete
extension MainCoreDataRepository {

    /// 追加処理
    public func insert(_ object: NSManagedObject) {
        viewContext.insert(object)
        saveContext()
    }
    
    /// 削除処理
    public func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        saveContext()
    }
}


// MARK: - Save
extension MainCoreDataRepository {
    /// Contextに応じたSave
    private func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch let error as NSError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
}


// MARK: - 取得
extension MainCoreDataRepository {
    
    public func fetch<T: NSManagedObject>() -> [T] {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        do {
            return try viewContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return []
        }
    }
    
    public func fetchSingle<T: NSManagedObject>(predicate: NSPredicate? = nil, sorts: [NSSortDescriptor]? = nil) -> T {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        // フィルタリング
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        var result: T!
        // ソート
        if let sorts = sorts {
            fetchRequest.sortDescriptors = sorts
        }
        
        do {
            let entitys = try viewContext.fetch(fetchRequest)
            if let entity = entitys.first {
                result = entity
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return result
    }

}
