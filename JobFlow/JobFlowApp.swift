//
//  JobFlowApp.swift
//  JobFlow
//
//  Created by Megan Brown on 7/4/25.
//

import SwiftUI

@main
struct JobFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
