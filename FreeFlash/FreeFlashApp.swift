//
//  FreeFlashApp.swift
//  FreeFlash
//
//  Created by Caleb Atchison on 3/17/26.
//

import SwiftUI
internal import CoreData

@main
struct FreeFlashApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MySetsView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
