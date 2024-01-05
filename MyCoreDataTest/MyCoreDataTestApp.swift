//
//  MyCoreDataTestApp.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import SwiftUI

@main
struct MyCoreDataTestApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
