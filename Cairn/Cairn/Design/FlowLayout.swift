//
//  FlowLayout.swift
//  Cairn
//

import SwiftUI

/// Wrapping row layout for chips. A grid would give every chip the same width, which
/// looks mechanical next to labels of very different lengths.
///
/// TODO: slice 6 — verify and fix placement under a right to left layout direction
/// before Arabic ships.
struct FlowLayout: Layout {
    /// Held as a constant rather than a stored property on purpose. A `Layout` is used as
    /// `FlowLayout { ... }`, which relies on the implicit no argument initialiser; adding
    /// an initialiser parameter makes that call ambiguous against `callAsFunction`.
    private let spacing = Space.s

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let rows = arrange(subviews: subviews, width: width)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY

        for row in arrange(subviews: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)

            if x + size.width > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                x = 0
            }

            current.indices.append(index)
            current.height = max(current.height, size.height)
            x += size.width + spacing
        }

        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
