//
//  PathView.swift
//  Cairn
//

import SwiftUI
import SwiftData

/// The milestones as a winding trail, so there is always a next thing to walk toward.
///
/// Milestones count free days, the same number the notifications use, so this screen
/// and the notifications can never disagree. Nothing on it can go backwards: a reached
/// milestone stays reached, and a slip only moves the next one a little further out.
struct PathView: View {
    @Query private var habits: [Habit]
    @Query(sort: \DayRecord.day, order: .reverse) private var usedDays: [DayRecord]

    private let milestones = MilestoneScheduler.milestones

    private var stats: QuitStats? {
        guard let habit = habits.first else { return nil }
        return QuitStats(
            quitStartedAt: habit.quitStartedAt,
            usedDays: Set(usedDays.map(\.day))
        )
    }

    private enum Stage { case reached, next, later }

    var body: some View {
        Screen {
            if let stats {
                let free = stats.lifetimeFreeDays
                let next = milestones.first { $0 > free }

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: Space.m) {
                            header(free: free)
                            trail(free: free, next: next)
                            Text("Milestones count free days, so a slip only moves the next one a little.")
                                .font(Typeface.voiceSmall)
                                .foregroundStyle(Palette.inkSoft)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, Space.m)
                        }
                        .padding(.top, Space.m)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .onAppear {
                        if let next { proxy.scrollTo(next, anchor: .center) }
                    }
                }
            }
        }
    }

    // MARK: - Pieces

    private func header(free: Int) -> some View {
        let reached = milestones.filter { $0 <= free }.count

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your path")
                    .font(Typeface.label)
                    .textCase(.uppercase)
                    .tracking(1.0)
                    .foregroundStyle(Palette.onAccent.opacity(0.8))
                Text("\(free) free days")
                    .font(Typeface.title)
                    .foregroundStyle(Palette.onAccent)
            }
            Spacer()
            Text("\(reached) of \(milestones.count)")
                .font(Typeface.label)
                .foregroundStyle(Palette.onAccent)
                .padding(.horizontal, Space.s + 2)
                .padding(.vertical, Space.s - 2)
                .background(Palette.accentDeep, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(Space.m + 2)
        .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button + 2))
        .background(
            RoundedRectangle(cornerRadius: Radius.button + 2)
                .fill(Palette.accentDeep)
                .offset(y: 4)
        )
        .accessibilityElement(children: .combine)
    }

    private func trail(free: Int, next: Int?) -> some View {
        let sway: [CGFloat] = [0, 52, 92, 52, 0, 52, 92, 52, 0]

        return VStack(alignment: .leading, spacing: Space.m) {
            ForEach(Array(milestones.enumerated()), id: \.element) { index, milestone in
                let state: Stage = milestone <= free ? .reached : (milestone == next ? .next : .later)

                HStack(spacing: Space.m - 2) {
                    node(state)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title(for: milestone))
                            .font(.system(.body, design: .rounded, weight: .heavy))
                            .foregroundStyle(Palette.ink)
                        Text(subtitle(for: state, milestone: milestone, free: free))
                            .font(Typeface.row)
                            .foregroundStyle(state == .next ? Palette.sunInk : Palette.inkSoft)
                    }
                }
                .padding(.leading, sway[index % sway.count])
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .id(milestone)
            }
        }
    }

    @ViewBuilder
    private func node(_ state: Stage) -> some View {
        switch state {
        case .reached:
            circle(size: 60, fill: Palette.leaf, edge: Palette.accentDeep) {
                Image(systemName: "checkmark")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Palette.onAccent)
            }
        case .next:
            circle(size: 68, fill: Palette.sun, edge: Palette.sunInk) {
                Image(systemName: "star.fill")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Palette.onAccent)
            }
            .overlay(Circle().stroke(Palette.sunQuiet, lineWidth: 6).padding(-6))
        case .later:
            circle(size: 60, fill: Palette.sunk, edge: Palette.hairline) {
                Image(systemName: "lock.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Palette.inkFaint)
            }
        }
    }

    private func circle<Content: View>(
        size: CGFloat, fill: Color, edge: Color, @ViewBuilder content: () -> Content
    ) -> some View {
        Circle()
            .fill(fill)
            .frame(width: size, height: size)
            .overlay(content())
            .background(Circle().fill(edge).frame(width: size, height: size).offset(y: 5))
            .padding(.bottom, 5)
    }

    // MARK: - Copy

    private func title(for milestone: Int) -> String {
        milestone >= 365
            ? String(localized: "1 year")
            : String(localized: "\(milestone) days")
    }

    private func subtitle(for state: Stage, milestone: Int, free: Int) -> String {
        switch state {
        case .reached: String(localized: "Reached")
        case .next: String(localized: "\(milestone - free) free days to go")
        case .later: String(localized: "Later")
        }
    }
}

#Preview {
    PathView()
        .modelContainer(for: [Habit.self, DayRecord.self, CravingEvent.self], inMemory: true)
}
