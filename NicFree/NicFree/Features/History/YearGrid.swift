//
//  YearGrid.swift
//  NicFree
//

import SwiftUI

/// Every day since the quit date, month by month like a calendar, in the same marks as
/// Home's week row: free days are leaf circles, used days are clay squares, today is a ring.
///
/// Used days differ in **shape as well as tone**, so the distinction survives colour
/// blindness and a greyscale screenshot. They are clay rather than red, because red is
/// alarm and alarm is shame.
///
/// `LazyVGrid` mirrors itself under a right to left layout direction, which is why the
/// grid needs no special handling for Arabic while `FlowLayout` does.
struct YearGrid: View {
    let points: [QuitStats.DayPoint]
    var calendar: Calendar = .current

    private let spacing: CGFloat = 6
    /// Fills a phone's card, and stops growing on iPad so a month still reads as a calendar.
    private let maxCell: CGFloat = 40

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(maximum: maxCell), spacing: spacing), count: 7)
    }

    private struct Month: Identifiable {
        let id: Date
        let points: [QuitStats.DayPoint]
    }

    /// Newest month first, so the days that matter most are at the top.
    private var months: [Month] {
        let grouped = Dictionary(grouping: points) {
            calendar.dateInterval(of: .month, for: $0.date)?.start ?? $0.date
        }
        return grouped
            .map { Month(id: $0.key, points: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.id > $1.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            ForEach(months) { month in
                VStack(alignment: .leading, spacing: Space.s) {
                    Text(month.id.formatted(.dateTime.month(.wide).year()))
                        .font(Typeface.row)
                        .foregroundStyle(Palette.ink)

                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(weekdayLetters.indices, id: \.self) { index in
                            Text(weekdayLetters[index])
                                .font(Typeface.label)
                                .foregroundStyle(Palette.inkFaint)
                                .accessibilityHidden(true)
                        }
                        ForEach(0..<leadingBlanks(for: month), id: \.self) { _ in
                            Color.clear.aspectRatio(1, contentMode: .fit)
                        }
                        ForEach(month.points) { point in
                            cell(for: point)
                        }
                    }
                    .frame(maxWidth: (maxCell + spacing) * 7)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    /// Short weekday letters, starting on the calendar's first weekday.
    private var weekdayLetters: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Empty cells so the month's first tracked day lands under its own weekday.
    private func leadingBlanks(for month: Month) -> Int {
        guard let first = month.points.first?.date else { return 0 }
        let weekday = calendar.component(.weekday, from: first)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    @ViewBuilder
    private func cell(for point: QuitStats.DayPoint) -> some View {
        let isToday = calendar.isDateInToday(point.date)
        Group {
            if point.wasUsed {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Palette.clayQuiet)
                    .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Palette.clay, lineWidth: 2))
            } else if isToday {
                Circle().strokeBorder(Palette.leaf, lineWidth: 3)
            } else {
                Circle().fill(Palette.leaf)
            }
        }
        // A little smaller than the cell, so a month of free days reads as dots, not a slab.
        .padding(4)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(label(for: point, isToday: isToday))
    }

    private func label(for point: QuitStats.DayPoint, isToday: Bool) -> String {
        let date = point.date.formatted(.dateTime.day().month(.wide))
        if point.wasUsed { return String(localized: "\(date), used") }
        return isToday ? String(localized: "\(date), today so far") : String(localized: "\(date), free")
    }
}

/// Shape is doing the work here too, so the key is not colour alone.
struct YearGridLegend: View {
    var body: some View {
        HStack(spacing: Space.m) {
            item("free") { Circle().fill(Palette.leaf) }
            item("used") {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Palette.clayQuiet)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Palette.clay, lineWidth: 1.5))
            }
            item("today") { Circle().strokeBorder(Palette.leaf, lineWidth: 2) }
        }
        .font(.caption)
        .foregroundStyle(Palette.inkSoft)
    }

    private func item(_ title: LocalizedStringKey, @ViewBuilder mark: () -> some View) -> some View {
        HStack(spacing: Space.xs + 2) {
            mark().frame(width: 12, height: 12)
            Text(title)
        }
    }
}
