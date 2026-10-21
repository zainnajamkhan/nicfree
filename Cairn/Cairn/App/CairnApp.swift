//
//  CairnApp.swift
//  Cairn
//
//  Created by Zain Najam Khan on 14/08/2026.
//

import SwiftUI
import SwiftData

@main
struct CairnApp: App {
    private let container: ModelContainer
    @State private var store = PurchaseStore()

    init() {
        container = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task { await store.start() }
        }
        .modelContainer(container)
    }

    /// Deliberately does not `fatalError` on a failed persistent store.
    ///
    /// The app's entire value is an accumulated record, so a crash loop on a damaged
    /// store is the worst outcome available: the user cannot even open the app to
    /// export what they have. Falling back to memory keeps it launchable so it can
    /// explain itself instead.
    ///
    /// CloudKit is intentionally absent until the developer account is active. It is
    /// added as a mirror in slice 5, never as the source of truth.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Habit.self, DayRecord.self, CravingEvent.self])

        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [onDisk]) {
            return container
        }

        // TODO: slice 6 — surface this state to the user rather than degrading silently.
        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [inMemory])
        } catch {
            fatalError("Could not create an in-memory container: \(error)")
        }
    }
}
