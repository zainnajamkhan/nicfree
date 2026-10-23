//
//  SettingsView.swift
//  NicFree
//

import SwiftUI
import SwiftData
import UserNotifications

/// Everything entered during onboarding can be changed here, because onboarding asks for
/// rough numbers under a minute and people come back to correct them.
///
/// Edits write straight to the habit. There is no Save button to forget.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(PurchaseStore.self) private var store

    @Bindable var habit: Habit

    @State private var reasons: [String] = ["", "", ""]
    @State private var weeklySpend: Double?
    @State private var notifications: UNAuthorizationStatus = .notDetermined
    @State private var reminderNote: String?
    #if DEBUG
    @State private var previewCelebration: CelebrationMoment?
    #endif

    var body: some View {
        NavigationStack {
            List {
                reasonsSection
                useSection
                notificationsSection
                aboutSection
                #if DEBUG
                debugSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(Palette.ground)
            .font(Typeface.row)
            #if DEBUG
            .fullScreenCover(item: $previewCelebration) { CelebrationView(moment: $0) }
            #endif
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(Typeface.row)
                }
            }
        }
        .tint(Palette.accent)
        .onAppear(perform: load)
        .onDisappear(perform: saveReasons)
        .task(id: scenePhase) {
            notifications = await MilestoneScheduler.authorizationStatus()
        }
    }

    // MARK: - Sections

    private var reasonsSection: some View {
        Section {
            ForEach(reasons.indices, id: \.self) { index in
                TextField("A reason, in your words", text: $reasons[index], axis: .vertical)
                    .font(Typeface.voiceSmall)
            }
        } header: {
            SectionLabel("Your reasons")
        } footer: {
            Text("You’ll see one of these each time a craving hits.")
        }
    }

    private var useSection: some View {
        Section {
            DatePicker("Quit date", selection: $habit.quitStartedAt, in: ...Date(), displayedComponents: .date)

            HStack {
                Text("Money spent each week")
                Spacer()
                TextField(
                    "Optional",
                    value: $weeklySpend,
                    format: .currency(code: habit.currencyCode).precision(.fractionLength(0))
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(maxWidth: 160)
                .onChange(of: weeklySpend) { _, value in
                    guard habit.baselineUnitsPerWeek > 0 else { return }
                    habit.costPerUnit = (value ?? 0) / habit.baselineUnitsPerWeek
                }
            }
        } header: {
            SectionLabel("What you used")
        } footer: {
            Text("Changing your quit date recounts every day since then. Spending only changes the money saved.")
        }
    }

    private var notificationsSection: some View {
        Section {
            HStack {
                Text("Milestone notes")
                Spacer()
                Text(notificationLabel).foregroundStyle(Palette.inkSoft)
            }

            switch notifications {
            case .notDetermined:
                Button("Turn on") {
                    Task {
                        _ = await MilestoneScheduler.requestAuthorization()
                        notifications = await MilestoneScheduler.authorizationStatus()
                    }
                }
            default:
                Button("Change in iPhone Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
            }

            Toggle("Evening check-in", isOn: reminderOn)
            if habit.eveningReminderMinute != nil {
                DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
            }
            if let reminderNote {
                Text(reminderNote).font(.footnote).foregroundStyle(Palette.inkSoft)
            }
        } header: {
            SectionLabel("Notifications")
        } footer: {
            Text("Little notes at 1 day, 3 days, a week, a month and beyond. The evening check-in is off unless you turn it on. You never need to do anything on a free day.")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(version).foregroundStyle(Palette.inkSoft).monospacedDigit()
            }
            Link("Help and support", destination: Self.supportURL)
            Link("Privacy policy", destination: Self.privacyURL)
        } header: {
            SectionLabel("About")
        } footer: {
            Text("Everything stays on this iPhone. No account, no tracking, nothing collected.")
        }
    }

    #if DEBUG
    private var debugSection: some View {
        @Bindable var store = store
        return Section {
            Toggle("Unlock everything", isOn: $store.debugUnlocked)
            Button("Preview a free day celebration") {
                previewCelebration = CelebrationMoment(from: 12, to: 13, milestone: nil)
            }
            Button("Preview a milestone celebration") {
                previewCelebration = CelebrationMoment(from: 6, to: 7, milestone: 7)
            }
        } header: {
            SectionLabel("Debug builds only")
        } footer: {
            Text("Not in the App Store version. Shows the paid screens without buying.")
        }
    }
    #endif

    // MARK: - Data

    // Hosted from the public repo zainnajamkhan/nicfree-site. The same two URLs go in App
    // Store Connect.
    private static let supportURL = URL(string: "https://zainnajamkhan.github.io/nicfree-site/")!
    private static let privacyURL = URL(string: "https://zainnajamkhan.github.io/nicfree-site/privacy.html")!

    private var reminderOn: Binding<Bool> {
        Binding(
            get: { habit.eveningReminderMinute != nil },
            set: { on in
                reminderNote = nil
                guard on else {
                    habit.eveningReminderMinute = nil
                    Task { await ReminderScheduler.update(minuteOfDay: nil) }
                    return
                }
                Task {
                    if await MilestoneScheduler.authorizationStatus() == .notDetermined {
                        _ = await MilestoneScheduler.requestAuthorization()
                    }
                    notifications = await MilestoneScheduler.authorizationStatus()
                    guard notifications == .authorized || notifications == .provisional else {
                        reminderNote = String(localized: "Notifications are off. Turn them on in iPhone Settings first.")
                        return
                    }
                    habit.eveningReminderMinute = ReminderScheduler.defaultMinute
                    await ReminderScheduler.update(minuteOfDay: ReminderScheduler.defaultMinute)
                }
            }
        )
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                let minute = habit.eveningReminderMinute ?? ReminderScheduler.defaultMinute
                return Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                let minute = (parts.hour ?? 20) * 60 + (parts.minute ?? 0)
                habit.eveningReminderMinute = minute
                Task { await ReminderScheduler.update(minuteOfDay: minute) }
            }
        )
    }

    private var notificationLabel: String {
        switch notifications {
        case .authorized, .provisional, .ephemeral: String(localized: "On")
        case .denied: String(localized: "Off")
        default: String(localized: "Not set")
        }
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private func load() {
        reasons = Array((habit.reasons + ["", "", ""]).prefix(3))
        let spend = habit.costPerUnit * habit.baselineUnitsPerWeek
        weeklySpend = spend > 0 ? spend.rounded() : nil
    }

    private func saveReasons() {
        habit.reasons = reasons
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
