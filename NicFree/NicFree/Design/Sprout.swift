//
//  Sprout.swift
//  NicFree
//

import SwiftUI

/// The mascot: a potted sprout that grows a little with every free day and gains leaves at
/// 3, 7 and 30.
///
/// A slip makes it **thirsty**: the leaves droop, the colour fades and the smile turns down,
/// until a full free day perks it up again (decided 2026-10-25). It never loses a leaf and
/// never shrinks, because the total never goes down. Drawn in code on a 150 point grid so
/// there are no image assets to manage.
struct Sprout: View {
    let freeDays: Int
    var thirsty: Bool = false

    /// 1 leaf at the start, 4 by a month.
    static func leafCount(freeDays: Int) -> Int {
        switch freeDays {
        case ..<3: 1
        case ..<7: 2
        case ..<30: 3
        default: 4
        }
    }

    /// The plant above the pot grows a little every free day, to full size at 60.
    static func growth(freeDays: Int) -> CGFloat {
        0.78 + 0.22 * CGFloat(min(max(freeDays, 0), 60)) / 60
    }

    var body: some View {
        let leaves = Self.leafCount(freeDays: freeDays)
        let growth = Self.growth(freeDays: freeDays)

        Canvas { context, size in
            let scale = min(size.width, size.height) / 150
            context.scaleBy(x: scale, y: scale)

            // The plant grows up out of the middle of the rim.
            var plant = context
            plant.translateBy(x: 75, y: 92)
            plant.scaleBy(x: growth, y: growth)
            plant.translateBy(x: -75, y: -92)

            var stem = Path()
            stem.move(to: CGPoint(x: 75, y: 92))
            stem.addCurve(to: CGPoint(x: 75, y: 40), control1: CGPoint(x: 75, y: 70), control2: CGPoint(x: 75, y: 55))
            plant.stroke(stem, with: .color(thirsty ? Self.thirstyStem : Palette.accent), style: StrokeStyle(lineWidth: 6, lineCap: .round))

            // Added in this order, so the plant fills out from the bottom. Each leaf droops
            // around where it meets the stem: left ones turn down to the left, right ones to the right.
            let leafShapes: [(path: Path, color: Color, base: CGPoint, droop: Double)] = [
                (leaf(from: (75, 78), c1: (60, 80), c2: (50, 72), to: (46, 60), c3: (60, 58), c4: (72, 64)), Color(light: 0x7CC97F, dark: 0x7CC97F), CGPoint(x: 75, y: 78), -32),
                (leaf(from: (75, 72), c1: (90, 74), c2: (100, 66), to: (104, 54), c3: (90, 52), c4: (78, 58)), Color(light: 0x66BB6A, dark: 0x66BB6A), CGPoint(x: 75, y: 72), 32),
                (leaf(from: (75, 62), c1: (55, 62), c2: (42, 50), to: (40, 34), c3: (58, 34), c4: (72, 44)), Palette.leaf, CGPoint(x: 75, y: 62), -28),
                (leaf(from: (75, 52), c1: (95, 52), c2: (108, 40), to: (110, 24), c3: (92, 24), c4: (78, 34)), Palette.leaf, CGPoint(x: 75, y: 52), 28),
            ]
            for (index, shape) in leafShapes.prefix(leaves).enumerated() {
                var leafContext = plant
                if thirsty {
                    leafContext.translateBy(x: shape.base.x, y: shape.base.y)
                    leafContext.rotate(by: .degrees(shape.droop))
                    leafContext.translateBy(x: -shape.base.x, y: -shape.base.y)
                }
                leafContext.fill(shape.path, with: .color(thirsty ? Self.thirstyLeaves[index] : shape.color))
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

            // A smile, or a small frown when thirsty.
            var mouth = Path()
            if thirsty {
                mouth.move(to: CGPoint(x: 67, y: 130))
                mouth.addQuadCurve(to: CGPoint(x: 83, y: 130), control: CGPoint(x: 75, y: 123))
            } else {
                mouth.move(to: CGPoint(x: 66, y: 126))
                mouth.addQuadCurve(to: CGPoint(x: 84, y: 126), control: CGPoint(x: 75, y: 133))
            }
            context.stroke(mouth, with: .color(face), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(thirsty
            ? "A thirsty potted sprout with \(leaves) leaves"
            : "A smiling potted sprout with \(leaves) leaves")
    }

    /// Faded, yellowed greens: dry, not dead, and never the clay or red of alarm.
    private static let thirstyStem = Color(light: 0x8A9A52, dark: 0x8A9A52)
    private static let thirstyLeaves = [
        Color(light: 0xC2CC8A, dark: 0xC2CC8A),
        Color(light: 0xB3C07A, dark: 0xB3C07A),
        Color(light: 0xA5B56C, dark: 0xA5B56C),
        Color(light: 0xA5B56C, dark: 0xA5B56C),
    ]

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
            HStack {
                Sprout(freeDays: days).frame(height: 120)
                Sprout(freeDays: days, thirsty: true).frame(height: 120)
            }
        }
    }
    .padding()
}
