//
//  CoreDataRepository.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import CoreData

class MulchCoreDataRepository {
    
    static let shared = MulchCoreDataRepository()
    
    private static let persistentName = "MyCoreDataTest"
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: MulchCoreDataRepository.persistentName)
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
}

// MARK: - Create
extension MulchCoreDataRepository {
    // MARK: - 返り値はメインスレッドでないと使えない？
    
    // perform/performAndWaitは処理の重さによって切り替える
    // https://appdev-room.com/swift-core-data-perform
    
    /// 新規作成：perform 完了ハンドラー Ver
    public func newEntity<T: NSManagedObject>(onBackgroundThread: Bool = false, completion: @escaping (T) -> Void) {
        let context = onBackgroundThread ? makeBackgroundContext() : makeContext()
        context.perform {
            let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
            let newObject = T(entity: entity, insertInto: context)
            completion(newObject)
        }
    }
    
    /// 新規作成：performAndWait 返り値 Ver
    public func newEntity<T: NSManagedObject>(onBackgroundThread: Bool = false) -> T {
        let context = onBackgroundThread ? makeBackgroundContext() : makeContext()
        var result: T!
        context.performAndWait {
            let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
            result = T(entity: entity, insertInto: context)
        }
        return result
    }
    
    
    /// 新規作成：performBackgroundTask 完了ハンドラー Ver
    /// performBackgroundTask メソッドは単発でバックグラウンドで行いたい処理があるときに使用する
    /// 生成したContextはクロージャーを抜けると破棄される
    public func newEntityBG<T: NSManagedObject>(completion: @escaping (T) -> Void) {
        persistentContainer.performBackgroundTask { context in
            let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
            let newObject = T(entity: entity, insertInto: context)
            completion(newObject)
        }
    }
    
}

// MARK: - Insert/Update/Delete
extension MulchCoreDataRepository {

    /// 追加処理
    public func insert(_ object: NSManagedObject, onBackgroundThread: Bool = false) {
        let context = onBackgroundThread ? object.managedObjectContext ?? makeBackgroundContext() : makeContext()
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
}


// MARK: - Save
extension MulchCoreDataRepository {
    /// Contextに応じたSave
    private func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch let error as NSError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
}


// MARK: - 取得
extension MulchCoreDataRepository {
    // MARK: - fetchはContextを切り分ける必要がない？
    
    // perform/performAndWaitは処理の重さによって切り替える
    // ・完了ハンドラー：非同期処理(重ための処理)
    // ・返り値　　　　：同期処理(軽めの処理)
    // https://appdev-room.com/swift-core-data-perform
    
    /// ALLData取得処理1：完了ハンドラーVer
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
    
    /// SingleDate取得処理：返り値Ver
    public func fetchSingle<T: NSManagedObject>(predicate: NSPredicate? = nil, sorts: [NSSortDescriptor]? = nil) -> T {
        let context = makeContext()
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))

        var result: T!
        context.performAndWait {
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
                    result = entity
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
        return result
    }
}
