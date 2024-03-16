//
//  MyCoreDataTestApp.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import SwiftUI

@main
struct MyCoreDataTestApp: App {
    private var mulch = true
    var body: some Scene {
        WindowGroup {
            if mulch {
                MulchListView()
            } else {
                MainListView()
            }
        }
    }
}
