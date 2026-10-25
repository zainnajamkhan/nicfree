//
//  NicFreeApp.swift
//  NicFree
//
//  Created by Zain Najam Khan on 14/08/2026.
//

import SwiftUI
import SwiftData

extension EnvironmentValues {
    /// True when the saved history could not be opened and the app is running on a
    /// temporary in-memory store.
    @Entry var storeIsTemporary = false
}

@main
struct NicFreeApp: App {
    private let container: ModelContainer
    private let storeIsTemporary: Bool
    @State private var store = PurchaseStore()

    init() {
        (container, storeIsTemporary) = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.storeIsTemporary, storeIsTemporary)
                .preferredColorScheme(Self.forcedScheme)
                .task {
                    // When the app is only hosting unit tests, the purchase test owns StoreKit.
                    // Starting here too races its test session for the product.
                    guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
                    await store.start()
                }
        }
        .modelContainer(container)
    }

    /// Lets a UI test check dark mode without depending on the simulator's setting.
    private static var forcedScheme: ColorScheme? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-forceDarkForUITests") { return .dark }
        #endif
        return nil
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
    private static func makeContainer() -> (ModelContainer, isTemporary: Bool) {
        let schema = Schema([Habit.self, DayRecord.self, CravingEvent.self])

        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        // App Store screenshots: a fresh in-memory store with a believable history in it.
        if arguments.contains("-seedScreenshotData"),
           let seeded = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]) {
            // 2 days back celebrates yesterday; 5 back passes the 60 day milestone.
            let celebrateDays: Int? = arguments.contains("-celebrateMilestoneForUITests") ? 5
                : arguments.contains("-celebrateForUITests") ? 2 : nil
            ScreenshotData.seed(
                into: seeded.mainContext,
                awayDays: arguments.contains("-simulateAwayForUITests") ? 3 : nil,
                celebrateDays: celebrateDays,
                slipYesterday: arguments.contains("-thirstyForUITests")
            )
            return (seeded, false)
        }
        // Every UI test launch starts from nothing, so tests never see each other's data.
        // Checked after the damage flag below would be too late, so that flag wins here.
        if arguments.contains("-freshStoreForUITests"), !arguments.contains("-simulateDamagedStore"),
           let fresh = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]) {
            return (fresh, false)
        }
        // Lets a UI test walk the damaged-store path without damaging anything.
        let simulateDamage = arguments.contains("-simulateDamagedStore")
        #else
        let simulateDamage = false
        #endif
        if !simulateDamage, let container = try? ModelContainer(for: schema, configurations: [onDisk]) {
            return (container, false)
        }

        // Home says so, so nobody logs a week of days that are never written down.
        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return (try ModelContainer(for: schema, configurations: [inMemory]), true)
        } catch {
            fatalError("Could not create an in-memory container: \(error)")
        }
    }
}
