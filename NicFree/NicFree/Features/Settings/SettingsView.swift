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

    @Bindable var habit: Habit

    @State private var reasons: [String] = ["", "", ""]
    @State private var weeklySpend: Double?
    @State private var notifications: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            List {
                reasonsSection
                useSection
                notificationsSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Palette.ground)
            .font(Typeface.row)
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
            Text("One of these comes back to you during each craving.")
        }
    }

    private var useSection: some View {
        Section {
            DatePicker("Quit date", selection: $habit.quitStartedAt, in: ...Date(), displayedComponents: .date)

            HStack {
                Text("Spent in a week")
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
            Text("Changing the quit date recounts every day since. Spending only shapes the money estimate.")
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
        } header: {
            SectionLabel("Notifications")
        } footer: {
            Text("A short note at a day, three days, a week, a month and later. Never a reminder to open the app.")
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

    // MARK: - Data

    // Hosted from the public repo zainnajamkhan/nicfree-site. The same two URLs go in App
    // Store Connect.
    private static let supportURL = URL(string: "https://zainnajamkhan.github.io/nicfree-site/")!
    private static let privacyURL = URL(string: "https://zainnajamkhan.github.io/nicfree-site/privacy.html")!

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
