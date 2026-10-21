//
//  Sprout.swift
//  Cairn
//

import SwiftUI

/// The mascot: a smiling potted sprout that gains leaves as free days add up.
///
/// It is static on purpose. It only ever gains leaves, it never wilts, and it looks the
/// same on a day someone slipped, because a mascot that frowns at a slip is shaming with
/// a face. Drawn in code on a 150 point grid so there are no image assets to manage.
struct Sprout: View {
    let freeDays: Int

    /// 1 leaf at the start, 4 by a month.
    static func leafCount(freeDays: Int) -> Int {
        switch freeDays {
        case ..<3: 1
        case ..<7: 2
        case ..<30: 3
        default: 4
        }
    }

    var body: some View {
        let leaves = Self.leafCount(freeDays: freeDays)

        Canvas { context, size in
            let scale = min(size.width, size.height) / 150
            context.scaleBy(x: scale, y: scale)

            var stem = Path()
            stem.move(to: CGPoint(x: 75, y: 92))
            stem.addCurve(to: CGPoint(x: 75, y: 40), control1: CGPoint(x: 75, y: 70), control2: CGPoint(x: 75, y: 55))
            context.stroke(stem, with: .color(Palette.accent), style: StrokeStyle(lineWidth: 6, lineCap: .round))

            // Added in this order, so the plant fills out from the bottom.
            let leafShapes: [(Path, Color)] = [
                (leaf(from: (75, 78), c1: (60, 80), c2: (50, 72), to: (46, 60), c3: (60, 58), c4: (72, 64)), Color(light: 0x7CC97F, dark: 0x7CC97F)),
                (leaf(from: (75, 72), c1: (90, 74), c2: (100, 66), to: (104, 54), c3: (90, 52), c4: (78, 58)), Color(light: 0x66BB6A, dark: 0x66BB6A)),
                (leaf(from: (75, 62), c1: (55, 62), c2: (42, 50), to: (40, 34), c3: (58, 34), c4: (72, 44)), Palette.leaf),
                (leaf(from: (75, 52), c1: (95, 52), c2: (108, 40), to: (110, 24), c3: (92, 24), c4: (78, 34)), Palette.leaf),
            ]
            for (path, color) in leafShapes.prefix(leaves) {
                context.fill(path, with: .color(color))
            }

            var pot = Path()
            pot.move(to: CGPoint(x: 40, y: 92))
            pot.addLine(to: CGPoint(x: 110, y: 92))
            pot.addLine(to: CGPoint(x: 102, y: 138))
            pot.addQuadCurve(to: CGPoint(x: 96, y: 143), control: CGPoint(x: 101, y: 143))
            pot.addLine(to: CGPoint(x: 54, y: 143))
            pot.addQuadCurve(to: CGPoint(x: 48, y: 138), control: CGPoint(x: 49, y: 143))
            pot.closeSubpath()
            context.fill(pot, with: .color(Palette.pot))

            let rim = Path(roundedRect: CGRect(x: 34, y: 86, width: 82, height: 14), cornerRadius: 7)
            context.fill(rim, with: .color(Palette.potRim))

            let face = Color(light: 0x3A2A1A, dark: 0x3A2A1A)
            context.fill(Path(ellipseIn: CGRect(x: 58, y: 112, width: 8, height: 8)), with: .color(face))
            context.fill(Path(ellipseIn: CGRect(x: 84, y: 112, width: 8, height: 8)), with: .color(face))

            var mouth = Path()
            mouth.move(to: CGPoint(x: 66, y: 126))
            mouth.addQuadCurve(to: CGPoint(x: 84, y: 126), control: CGPoint(x: 75, y: 133))
            context.stroke(mouth, with: .color(face), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A smiling potted sprout with \(leaves) leaves")
    }

    private func leaf(
        from: (CGFloat, CGFloat), c1: (CGFloat, CGFloat), c2: (CGFloat, CGFloat),
        to: (CGFloat, CGFloat), c3: (CGFloat, CGFloat), c4: (CGFloat, CGFloat)
    ) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: from.0, y: from.1))
        path.addCurve(to: CGPoint(x: to.0, y: to.1), control1: CGPoint(x: c1.0, y: c1.1), control2: CGPoint(x: c2.0, y: c2.1))
        path.addCurve(to: CGPoint(x: from.0, y: from.1), control1: CGPoint(x: c3.0, y: c3.1), control2: CGPoint(x: c4.0, y: c4.1))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack {
        ForEach([0, 3, 10, 63], id: \.self) { days in
            Sprout(freeDays: days).frame(height: 120)
        }
    }
    .padding()
}
