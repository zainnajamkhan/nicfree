//
//  YearGrid.swift
//  NicFree
//

import SwiftUI

/// Every day since the quit date, one cell each, aligned to weekday columns.
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

    private let spacing: CGFloat = 3

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: 7)
    }

    /// Empty cells so the first real day lands under its own weekday.
    private var leadingBlanks: Int {
        guard let first = points.first?.date else { return 0 }
        let weekday = calendar.component(.weekday, from: first)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear.aspectRatio(1, contentMode: .fit)
            }

            ForEach(points) { point in
                cell(for: point)
            }
        }
    }

    @ViewBuilder
    private func cell(for point: QuitStats.DayPoint) -> some View {
        Group {
            if point.wasUsed {
                Circle().fill(Palette.clayQuiet)
            } else {
                RoundedRectangle(cornerRadius: 2).fill(Palette.accentQuiet)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(label(for: point))
    }

    private func label(for point: QuitStats.DayPoint) -> String {
        let date = point.date.formatted(.dateTime.day().month(.wide))
        return point.wasUsed
            ? String(localized: "\(date), used")
            : String(localized: "\(date), free")
    }
}

/// Shape is doing the work here too, so the key is not colour alone.
struct YearGridLegend: View {
    var body: some View {
        HStack(spacing: Space.m) {
            HStack(spacing: Space.xs + 2) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Palette.accentQuiet)
                    .frame(width: 10, height: 10)
                Text("free")
            }
            HStack(spacing: Space.xs + 2) {
                Circle()
                    .fill(Palette.clayQuiet)
                    .frame(width: 10, height: 10)
                Text("used")
            }
        }
        .font(.caption)
        .foregroundStyle(Palette.inkFaint)
    }
}
