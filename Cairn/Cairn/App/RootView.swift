//
//  RootView.swift
//  Cairn
//

import SwiftUI
import SwiftData

/// The presence of a habit is the only thing that decides whether onboarding runs, so
/// there is no separate "has onboarded" flag to fall out of sync with the data.
struct RootView: View {
    @Environment(\.storeIsTemporary) private var storeIsTemporary
    @Query private var habits: [Habit]
    @State private var acknowledgedTemporaryStore = false

    var body: some View {
        Group {
            if storeIsTemporary, habits.isEmpty, !acknowledgedTemporaryStore {
                // Without this, a store that failed to open looks exactly like a wiped
                // app: straight into onboarding.
                TemporaryStoreView { acknowledgedTemporaryStore = true }
            } else if habits.isEmpty {
                OnboardingView()
            } else {
                MainTabs()
            }
        }
        .animation(.smooth(duration: 0.4), value: habits.isEmpty)
    }
}

private struct TemporaryStoreView: View {
    let onContinue: () -> Void

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: Space.m) {
                Spacer()
                Text("Your saved history could not be opened")
                    .font(Typeface.title)
                    .foregroundStyle(Palette.ink)
                Text("NicFree has not deleted anything. Close it fully and open it again. If you carry on now, nothing you log will be kept.")
                    .font(Typeface.voiceSmall)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                SecondaryButton("Carry on without saving", action: onContinue)
                    .padding(.bottom, Space.l)
            }
        }
    }
}

/// Home, the milestone path, the record, and the paid Insights screen.
private struct MainTabs: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            PathView()
                .tabItem { Label("Path", systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill") }

            NavigationStack { HistoryView() }
                .tabItem { Label("History", systemImage: "calendar") }

            NavigationStack { InsightsView() }
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
        .tint(Palette.accent)
    }
}

#Preview {
    RootView()
        .environment(PurchaseStore())
        .modelContainer(for: [Habit.self, DayRecord.self, CravingEvent.self], inMemory: true)
}
