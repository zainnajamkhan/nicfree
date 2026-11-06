//
//  Sprout.swift
//  NicFree
//

import SwiftUI

/// The mascot: a potted sprout that grows with every finished free day and changes at each
/// milestone, from a single leaf to a golden plant in full bloom at a year.
///
/// A slip makes it **thirsty**: the leaves droop, the colour fades and the smile turns down,
/// until a full free day perks it up again (decided 2026-10-25). It never loses a leaf, a bud
/// or a flower and never shrinks, because it's drawn from **finished** free days, which a
/// slip today can't lower. Drawn in code on a 150 point grid so there are no image assets.
///
/// `days` is continuous so it can be animated: going from 29 to 30 opens the flower,
/// and going from 0 to 365 plays the whole life of the plant, one stage after another.
struct Sprout: View, Animatable {
    var days: Double
    var thirsty: Bool = false

    init(freeDays: Int, thirsty: Bool = false) {
        self.days = Double(freeDays)
        self.thirsty = thirsty
    }

    init(days: Double, thirsty: Bool = false) {
        self.days = days
        self.thirsty = thirsty
    }

    var animatableData: Double {
        get { days }
        set { days = newValue }
    }

    // MARK: - Stages

    struct Stage: Equatable {
        let day: Int
        let name: LocalizedStringResource
    }

    /// Each stage arrives on a milestone, so the plant and the path always agree.
    static let stages: [Stage] = [
        Stage(day: 0, name: "Seedling"),
        Stage(day: 3, name: "Second leaf"),
        Stage(day: 7, name: "Third leaf"),
        Stage(day: 14, name: "First bud"),
        Stage(day: 30, name: "First flower"),
        Stage(day: 60, name: "Second flower"),
        Stage(day: 90, name: "Full bloom"),
        Stage(day: 180, name: "Painted pot"),
        Stage(day: 365, name: "Golden sprout"),
    ]

    /// The index into `stages` for a number of finished free days.
    static func stageIndex(freeDays: Int) -> Int {
        max(0, (stages.lastIndex { $0.day <= freeDays }) ?? 0)
    }

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
    static func growth(days: Double) -> CGFloat {
        0.78 + 0.22 * CGFloat(min(max(days, 0), 60)) / 60
    }

    /// 0 before a stage, 1 once it's reached, and in between while animating toward it.
    private func appear(_ day: Int) -> CGFloat {
        guard day > 0 else { return 1 }
        return CGFloat(min(max(days - Double(day) + 1, 0), 1))
    }

    // MARK: - Drawing

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 150
            context.scaleBy(x: scale, y: scale)

            // A year in: a warm glow behind the whole plant.
            let golden = appear(365)
            if golden > 0 {
                let glow = Path(ellipseIn: CGRect(x: 15, y: 0, width: 120, height: 120))
                context.fill(glow, with: .radialGradient(
                    Gradient(colors: [Self.gold.opacity(0.55 * golden), Self.gold.opacity(0)]),
                    center: CGPoint(x: 75, y: 55), startRadius: 4, endRadius: 62
                ))
            }

            // The plant grows up out of the middle of the rim.
            var plant = context
            plant.translateBy(x: 75, y: 92)
            plant.scaleBy(x: Self.growth(days: days), y: Self.growth(days: days))
            plant.translateBy(x: -75, y: -92)

            // The stem only reaches as high as the plant has grown, so it never sticks out
            // bare above the leaves: just past the top leaf, then up to the bud at two weeks.
            let stemTop = 72 - 6 * appear(3) - 10 * appear(7) - 16 * appear(14)
            var stem = Path()
            stem.move(to: CGPoint(x: 75, y: 92))
            stem.addLine(to: CGPoint(x: 75, y: stemTop))
            plant.stroke(stem, with: .color(thirsty ? Self.thirstyStem : Palette.accent), style: StrokeStyle(lineWidth: 6, lineCap: .round))

            // Added in this order, so the plant fills out from the bottom. Each leaf droops
            // around where it meets the stem: left ones turn down to the left, right ones to the right.
            let leafShapes: [(day: Int, path: Path, color: Color, base: CGPoint, droop: Double)] = [
                (0, leaf(from: (75, 78), c1: (60, 80), c2: (50, 72), to: (46, 60), c3: (60, 58), c4: (72, 64)), Color(light: 0x7CC97F, dark: 0x7CC97F), CGPoint(x: 75, y: 78), -32),
                (3, leaf(from: (75, 72), c1: (90, 74), c2: (100, 66), to: (104, 54), c3: (90, 52), c4: (78, 58)), Color(light: 0x66BB6A, dark: 0x66BB6A), CGPoint(x: 75, y: 72), 32),
                (7, leaf(from: (75, 62), c1: (55, 62), c2: (42, 50), to: (40, 34), c3: (58, 34), c4: (72, 44)), Palette.leaf, CGPoint(x: 75, y: 62), -28),
                (30, leaf(from: (75, 52), c1: (95, 52), c2: (108, 40), to: (110, 24), c3: (92, 24), c4: (78, 34)), Palette.leaf, CGPoint(x: 75, y: 52), 28),
            ]
            for (index, shape) in leafShapes.enumerated() {
                let amount = appear(shape.day)
                guard amount > 0 else { continue }
                var leafContext = plant
                // A new leaf unfurls from where it meets the stem.
                leafContext.translateBy(x: shape.base.x, y: shape.base.y)
                if thirsty { leafContext.rotate(by: .degrees(shape.droop)) }
                leafContext.scaleBy(x: amount, y: amount)
                leafContext.translateBy(x: -shape.base.x, y: -shape.base.y)
                leafContext.fill(shape.path, with: .color(thirsty ? Self.thirstyLeaves[index] : shape.color))
            }

            // A bud at the top at two weeks, which opens into a flower at a month.
            let bud = appear(14) * (1 - appear(30))
            if bud > 0 {
                var budContext = plant
                budContext.translateBy(x: 75, y: 40)
                budContext.scaleBy(x: bud, y: bud)
                budContext.fill(Path(ellipseIn: CGRect(x: -6, y: -14, width: 12, height: 16)), with: .color(thirsty ? Self.thirstyLeaves[2] : Palette.leaf))
                budContext.fill(Path(ellipseIn: CGRect(x: -4, y: -15, width: 8, height: 8)), with: .color(Self.petal.opacity(thirsty ? 0.5 : 1)))
            }
            flower(in: plant, at: CGPoint(x: 75, y: 36), radius: 11, amount: appear(30), petal: Self.petal)
            flower(in: plant, at: CGPoint(x: 41, y: 36), radius: 7, amount: appear(60), petal: Self.petalSun)
            flower(in: plant, at: CGPoint(x: 109, y: 26), radius: 7, amount: appear(90), petal: Self.petalSky)

            var pot = Path()
            pot.move(to: CGPoint(x: 40, y: 92))
            pot.addLine(to: CGPoint(x: 110, y: 92))
            pot.addLine(to: CGPoint(x: 102, y: 138))
            pot.addQuadCurve(to: CGPoint(x: 96, y: 143), control: CGPoint(x: 101, y: 143))
            pot.addLine(to: CGPoint(x: 54, y: 143))
            pot.addQuadCurve(to: CGPoint(x: 48, y: 138), control: CGPoint(x: 49, y: 143))
            pot.closeSubpath()
            context.fill(pot, with: .color(Palette.pot))

            // Six months: little flowers painted on the pot.
            let painted = appear(180)
            if painted > 0 {
                for (x, y) in [(50.0, 104.0), (100.0, 104.0), (54.0, 132.0), (96.0, 132.0)] {
                    dot(in: context, at: CGPoint(x: x, y: y), radius: 3.2 * painted)
                }
            }

            let rim = Path(roundedRect: CGRect(x: 34, y: 86, width: 82, height: 14), cornerRadius: 7)
            context.fill(rim, with: .color(Palette.potRim))
            if golden > 0 {
                context.fill(rim, with: .color(Self.gold.opacity(golden)))
                // A few sparkles around the crown.
                for (x, y, r) in [(28.0, 30.0, 4.0), (122.0, 44.0, 5.0), (36.0, 70.0, 3.0), (118.0, 12.0, 3.0)] {
                    sparkle(in: context, at: CGPoint(x: x, y: y), radius: r * golden)
                }
            }

            let face = Color(light: 0x3A2A1A, dark: 0x3A2A1A)
            context.fill(Path(ellipseIn: CGRect(x: 58, y: 112, width: 8, height: 8)), with: .color(face))
            context.fill(Path(ellipseIn: CGRect(x: 84, y: 112, width: 8, height: 8)), with: .color(face))
            // Rosy cheeks from the first flower on.
            let rosy = appear(30)
            if rosy > 0, !thirsty {
                context.fill(Path(ellipseIn: CGRect(x: 51, y: 121, width: 9, height: 5)), with: .color(Self.cheek.opacity(0.7 * rosy)))
                context.fill(Path(ellipseIn: CGRect(x: 90, y: 121, width: 9, height: 5)), with: .color(Self.cheek.opacity(0.7 * rosy)))
            }

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
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let stage = String(localized: Self.stages[Self.stageIndex(freeDays: Int(days))].name)
        return thirsty
            ? String(localized: "A thirsty potted sprout, \(stage)")
            : String(localized: "A smiling potted sprout, \(stage)")
    }

    // MARK: - Pieces

    private func flower(in context: GraphicsContext, at center: CGPoint, radius: CGFloat, amount: CGFloat, petal: Color) {
        guard amount > 0 else { return }
        var flower = context
        flower.translateBy(x: center.x, y: center.y)
        // Thirsty flowers hang their heads a little and fade. They never fall off.
        if thirsty { flower.rotate(by: .degrees(18)) }
        flower.scaleBy(x: amount, y: amount)
        flower.rotate(by: .degrees(Double(1 - amount) * -90))
        let color = thirsty ? petal.opacity(0.5) : petal
        for index in 0..<5 {
            let angle = Double(index) / 5 * 2 * .pi - .pi / 2
            let x = cos(angle) * radius * 0.62
            let y = sin(angle) * radius * 0.62
            flower.fill(Path(ellipseIn: CGRect(x: x - radius * 0.48, y: y - radius * 0.48, width: radius * 0.96, height: radius * 0.96)), with: .color(color))
        }
        flower.fill(Path(ellipseIn: CGRect(x: -radius * 0.36, y: -radius * 0.36, width: radius * 0.72, height: radius * 0.72)), with: .color(Self.flowerHeart))
    }

    private func dot(in context: GraphicsContext, at center: CGPoint, radius: CGFloat) {
        guard radius > 0 else { return }
        for index in 0..<4 {
            let angle = Double(index) / 4 * 2 * .pi
            let x = center.x + cos(angle) * radius * 0.7
            let y = center.y + sin(angle) * radius * 0.7
            context.fill(Path(ellipseIn: CGRect(x: x - radius * 0.55, y: y - radius * 0.55, width: radius * 1.1, height: radius * 1.1)), with: .color(Self.potPaint))
        }
        context.fill(Path(ellipseIn: CGRect(x: center.x - radius * 0.4, y: center.y - radius * 0.4, width: radius * 0.8, height: radius * 0.8)), with: .color(Self.flowerHeart))
    }

    private func sparkle(in context: GraphicsContext, at center: CGPoint, radius: CGFloat) {
        guard radius > 0 else { return }
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addQuadCurve(to: CGPoint(x: center.x + radius, y: center.y), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + radius), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x - radius, y: center.y), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - radius), control: center)
        context.fill(path, with: .color(Self.gold))
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

    // MARK: - Colours

    /// Faded, yellowed greens: dry, not dead, and never the clay or red of alarm.
    private static let thirstyStem = Color(light: 0x8A9A52, dark: 0x8A9A52)
    private static let thirstyLeaves = [
        Color(light: 0xC2CC8A, dark: 0xC2CC8A),
        Color(light: 0xB3C07A, dark: 0xB3C07A),
        Color(light: 0xA5B56C, dark: 0xA5B56C),
        Color(light: 0xA5B56C, dark: 0xA5B56C),
    ]
    private static let petal = Color(light: 0xF6A5C0, dark: 0xF6A5C0)
    private static let petalSun = Color(light: 0xFFD166, dark: 0xFFD166)
    private static let petalSky = Color(light: 0xA9D6F5, dark: 0xA9D6F5)
    private static let flowerHeart = Color(light: 0xFFF3C4, dark: 0xFFF3C4)
    private static let potPaint = Color(light: 0xFFE0B8, dark: 0xFFE0B8)
    private static let cheek = Color(light: 0xF28B82, dark: 0xF28B82)
    private static let gold = Color(light: 0xF2C14B, dark: 0xF2C14B)
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
            ForEach(Sprout.stages, id: \.day) { stage in
                VStack {
                    Sprout(freeDays: stage.day).frame(height: 110)
                    Text(stage.name).font(.caption)
                }
            }
            Sprout(freeDays: 400, thirsty: true).frame(height: 110)
        }
    }
    .padding()
}
