//
//  RootView.swift
//  Cairn
//

import SwiftUI
import SwiftData

/// The presence of a habit is the only thing that decides whether onboarding runs, so
/// there is no separate "has onboarded" flag to fall out of sync with the data.
struct RootView: View {
    @Query private var habits: [Habit]

    var body: some View {
        Group {
            if habits.isEmpty {
                OnboardingView()
            } else {
                HomeView()
            }
        }
        .animation(.smooth(duration: 0.4), value: habits.isEmpty)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Habit.self, DayRecord.self, CravingEvent.self], inMemory: true)
}
