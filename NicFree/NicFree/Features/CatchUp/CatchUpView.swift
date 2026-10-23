//
//  CatchUpView.swift
//  NicFree
//

import SwiftUI

/// Asked once on return after a day or more away: any nicotine on the days the app did not
/// see? One tap for "all free". Picking days records them as slips.
///
/// Never framed as a missed check-in. The days were already counted as free; this only lets
/// someone correct that if they want to.
struct CatchUpView: View {
    @Environment(\.dismiss) private var dismiss

    let days: [Date]
    /// Called with the days picked as used, empty for "all free".
    let onFinish: ([Date]) -> Void

    @State private var pickingDays = false
    @State private var picked: Set<Date> = []

    var body: some View {
        Screen {
            PinnedActions {
                VStack(alignment: .leading, spacing: Space.m) {
                    SectionLabel("Welcome back")
                    Text("Any nicotine since \(since)?")
                        .font(Typeface.title)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if pickingDays {
                        Text("Tap the days you used. The rest stay free.")
                            .font(Typeface.row)
                            .foregroundStyle(Palette.inkSoft)
                        FlowLayout {
                            ForEach(days, id: \.self) { day in
                                Chip(label(for: day), isOn: picked.contains(day)) {
                                    if picked.contains(day) { picked.remove(day) } else { picked.insert(day) }
                                }
                            }
                        }
                    } else {
                        Text("Those days already count as free. This is just in case you forgot to log a slip.")
                            .font(Typeface.row)
                            .foregroundStyle(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, Space.l)
            } actions: {
                VStack(spacing: Space.s) {
                    if pickingDays {
                        PrimaryButton("Save") { finish(with: Array(picked)) }
                            .disabled(picked.isEmpty)
                            .opacity(picked.isEmpty ? 0.4 : 1)
                        SecondaryButton("They were all free") { finish(with: []) }
                    } else {
                        PrimaryButton("All free") { finish(with: []) }
                        SecondaryButton("Yes, on some days") {
                            withAnimation(.smooth(duration: 0.25)) { pickingDays = true }
                        }
                    }
                }
            }
        }
    }

    private func finish(with days: [Date]) {
        onFinish(days)
        dismiss()
    }

    /// "Tuesday" within the last week, "3 October" further back.
    private var since: String {
        guard let first = days.first else { return "" }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date())) ?? first
        return first >= weekAgo
            ? first.formatted(.dateTime.weekday(.wide))
            : first.formatted(.dateTime.day().month(.wide))
    }

    private func label(for day: Date) -> String {
        day.formatted(.dateTime.weekday(.abbreviated).day())
    }
}

#Preview {
    let today = Calendar.current.startOfDay(for: Date())
    let days = (1...3).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }
    return CatchUpView(days: days) { _ in }
}
