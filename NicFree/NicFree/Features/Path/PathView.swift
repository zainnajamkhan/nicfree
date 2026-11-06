//
//  PathView.swift
//  NicFree
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

    @State private var sharing: ShareMoment?

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
                let finished = stats.finishedFreeDays
                let next = milestones.first { $0 > finished }

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: Space.m) {
                            header(free: free, finished: finished)
                            sproutCard(finished: finished)
                            trail(finished: finished, next: next)
                            Text("Milestones count free days, so a slip only moves the next one a little.")
                                .font(Typeface.voiceSmall)
                                .foregroundStyle(Palette.inkSoft)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, Space.m)
                        }
                        .padding(.top, Space.m)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .sheet(item: $sharing) { ShareCardSheet(moment: $0) }
                    .onAppear {
                        // Low on screen rather than centred, so the header stays in view.
                        if let next { proxy.scrollTo(next, anchor: UnitPoint(x: 0.5, y: 0.8)) }
                    }
                }
            }
        }
    }

    // MARK: - Pieces

    private func header(free: Int, finished: Int) -> some View {
        let reached = milestones.filter { $0 <= finished }.count

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your path")
                    .font(Typeface.label)
                    .textCase(.uppercase)
                    .tracking(1.0)
                    .foregroundStyle(Palette.onAccent.opacity(0.8))
                Text(String(inflecting: "^[\(free) free day](inflect: true)"))
                    .font(Typeface.title)
                    .foregroundStyle(Palette.onAccent)
            }
            Spacer()
            Button {
                sharing = ShareMoment(days: free, sproutDays: finished, milestone: nil)
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.callout.weight(.heavy))
                    .foregroundStyle(Palette.onAccent)
                    .frame(width: 44, height: 44)
                    .background(Palette.accentDeep, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share your progress")
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
        .accessibilityElement(children: .contain)
    }

    // MARK: - Sprout

    /// The plant's life so far, and what it turns into next.
    private func sproutCard(finished: Int) -> some View {
        let index = Sprout.stageIndex(freeDays: finished)
        let stage = Sprout.stages[index]
        let next = index + 1 < Sprout.stages.count ? Sprout.stages[index + 1] : nil

        return HStack(spacing: Space.m) {
            Sprout(freeDays: finished)
                .frame(width: 110, height: 110)

            VStack(alignment: .leading, spacing: Space.xs) {
                SectionLabel("Your sprout")
                Text(stage.name)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                if let next {
                    Text(String(localized: "Next: \(String(localized: next.name)) at \(next.day) days"))
                        .font(Typeface.row)
                        .foregroundStyle(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Space.m)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Palette.hairline, lineWidth: 2)
        )
    }

    private func trail(finished free: Int, next: Int?) -> some View {
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
                        if let subtitle = subtitle(for: state, milestone: milestone, free: free) {
                            Text(subtitle)
                                .font(Typeface.row)
                                .foregroundStyle(state == .next ? Palette.sunInk : Palette.inkSoft)
                        }
                    }
                }
                // The next milestone's halo reaches past its circle, so even the first row keeps
                // a margin or the halo is clipped at the screen's edge.
                .padding(.leading, sway[index % sway.count] + 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                // A reached milestone opens its own card to share.
                .onTapGesture {
                    guard state == .reached else { return }
                    sharing = ShareMoment(days: milestone, sproutDays: milestone, milestone: milestone)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(state == .reached ? .isButton : [])
                .accessibilityHint(state == .reached ? String(localized: "Share this milestone") : "")
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
            circle(size: 60, fill: Palette.locked, edge: Palette.lockedEdge) {
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
            : String(inflecting: "^[\(milestone) day](inflect: true)")
    }

    /// Only the reached ones and the next one get a line; the rest just show their number.
    private func subtitle(for state: Stage, milestone: Int, free: Int) -> String? {
        switch state {
        case .reached: String(localized: "Reached · tap to share")
        case .next: String(inflecting: "Upcoming · ^[\(milestone - free) free day](inflect: true) to go")
        case .later: nil
        }
    }
}

#Preview {
    PathView()
        .modelContainer(for: [Habit.self, DayRecord.self, CravingEvent.self], inMemory: true)
}
