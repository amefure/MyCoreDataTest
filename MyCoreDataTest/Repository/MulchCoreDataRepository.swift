//
//  CoreDataRepository.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import CoreData

// MARK: - (1) マルチスレッドに対応するには？
// → スレッドごとにContextを切り分ける必要がある
// → メインスレッドとバックグラウンドスレッド用を用意する


// MARK: -  (2) バックグラウンドスレッド用のContextを扱うには？
// → newBackgroundContextやperformBackgroundTaskでBG用のContextを生成
// → newBackgroundContextは再利用できる
// → performBackgroundTaskは使い捨て
// → newBackgroundContextの場合はデータの読み書きはperform/performAndWait内で必ず行う
// → perform/performAndWaitは処理の重さによって切り替える
// → ・perform           ：非同期処理(重ための処理)
// → ・performAndWait    ：同期処理(軽めの処理)
// https://appdev-room.com/swift-core-data-perform

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
    // MARK: - (3) performAndWaitを使用した返り値形式はメインスレッドでないと使えない？
    /// インスタンス生成後にエンティティのプロパティに値を設定するとクラッシュした
    
    /// ①  各Context & perform 完了ハンドラー
    /// メインスレッドで実行可能
    public func newEntity<T: NSManagedObject>() -> T {
        let context = makeContext()
        let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
        return T(entity: entity, insertInto: context)
    }
    
    /// ②  各Context & perform/performAndWait 完了ハンドラー
    /// メイン&バックグラウンドスレッドで実行可能
    public func newEntity<T: NSManagedObject>(onBackgroundThread: Bool = false, completion: @escaping (T) -> Void) {
        let context = onBackgroundThread ? makeBackgroundContext() : makeContext()
        context.perform {
            let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
            let newObject = T(entity: entity, insertInto: context)
            completion(newObject)
        }
    }
    
    /// ②  の引数違い
    /// メイン&バックグラウンドスレッドで実行可能
    public func newEntity<T: NSManagedObject>(onBackgroundThread: Bool = false) -> T {
        let context = onBackgroundThread ? makeBackgroundContext() : makeContext()
        var result: T!
        context.performAndWait {
            let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
            result = T(entity: entity, insertInto: context)
        }
        return result
    }
    
    /// ③ 使い捨てContext (performBackgroundTask)
    /// メイン&バックグラウンドスレッドで実行可能
    /// performBackgroundTask メソッドは単発でバックグラウンドで行いたい処理があるときなどに使用する
    /// 生成したContextはクロージャーを抜けると破棄される
    public func newEntityDisposable<T: NSManagedObject>(completion: @escaping (T) -> Void) {
        persistentContainer.performBackgroundTask { context in
            let entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: context)!
            let newObject = T(entity: entity, insertInto: context)
            completion(newObject)
        }
    }
    
}

// MARK: - Insert/Update/Delete
extension MulchCoreDataRepository {
    // ここは基本的なNSManagedObjectに連携されているContextを使用する
    
    /// 追加処理
    public func insert(_ object: NSManagedObject) {
        let context = object.managedObjectContext ?? makeContext()
        saveContext(context)
    }
    
    /// 更新処理
    public func update(_ object: NSManagedObject) {
        let context = object.managedObjectContext ?? makeContext()
        saveContext(context)
    }
    
    /// 削除処理
    public func delete(_ object: NSManagedObject) {
        let context = object.managedObjectContext ?? makeContext()
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
    // MARK: - (4) fetchはスレッドごとにContextを切り分ける必要がない？
    /// BGスレッドでBGContextからから③のfetchを実行してもクラッシュはしないが値が取得できなかった
    /// ②ならBGスレッドで正常にフェッチが可能だった
    /// つまり②の形式ならメインでもバックグラウンドでも使用できるスレードセーフな実装？
    
    /// ① MainContext
    /// メインスレッドで実行可能
    /// UIに反映させるためのデータを取得したい時に使用する形式
    /// バックグラウンドスレッドで実行するとエラーになる
    public func fetch<T: NSManagedObject>() -> [T] {
        let context = makeContext()
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))

        do {
            let fetchedObjects = try context.fetch(fetchRequest)
            return fetchedObjects
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return []
        }
    }
    
    /// ②  MainContext & perform/performAndWait
    /// メイン&バックグラウンドスレッドで実行可能
    /// UIにそのまま反映させることも可能
    public func fetchBG<T: NSManagedObject>() -> [T] {
        let context = makeContext()
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))

        var result: [T] = []
        context.performAndWait {
            do {
                let fetchedObjects = try context.fetch(fetchRequest)
                result = fetchedObjects
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
        return result
    }
    
    /// ②  の引数違い
    /// こちらは結果を完了ハンドラーで受け取る
    public func fetchBG<T: NSManagedObject>(completion: @escaping ([T]) -> Void) {
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
    
    
    /// ③ BGContext & perform/performAndWait
    /// バックグラウンドスレッドで実行可能想定
    /// BGスレッドから呼び出してみたが総数は取得できたようだがプロパティがnullになった
    /// 原因はBGContextを使用しているため
    /// つまりこのメソッドは使えない
    public func fetchBGNone<T: NSManagedObject>(completion: @escaping ([T]) -> Void) {
        let context = makeBackgroundContext()
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
    
    
    /// ②  MainContext & perform/performAndWait 形式
    /// 1つのEntityを取得する用のメソッド
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
