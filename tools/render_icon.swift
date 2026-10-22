import AppKit
import CoreGraphics

// Renders the NicFree app icon from the same 150-point sprout geometry as Sprout.swift.
// Usage: swift render_icon.swift <output-folder>

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

func gray(_ hex: UInt32) -> CGColor {
    let r = CGFloat((hex >> 16) & 0xFF), g = CGFloat((hex >> 8) & 0xFF), b = CGFloat(hex & 0xFF)
    let l = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    return CGColor(gray: l, alpha: 1)
}

enum Variant { case light, dark, tinted, launch }

func leaf(_ ctx: CGContext, _ p: [CGFloat]) {
    ctx.beginPath()
    ctx.move(to: CGPoint(x: p[0], y: p[1]))
    ctx.addCurve(to: CGPoint(x: p[6], y: p[7]), control1: CGPoint(x: p[2], y: p[3]), control2: CGPoint(x: p[4], y: p[5]))
    ctx.addCurve(to: CGPoint(x: p[0], y: p[1]), control1: CGPoint(x: p[8], y: p[9]), control2: CGPoint(x: p[10], y: p[11]))
    ctx.closePath()
    ctx.fillPath()
}

func render(_ variant: Variant, size: Int = 1024, to url: URL) {
    let space = variant == .tinted ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB()
    let info = variant == .tinted ? CGImageAlphaInfo.none.rawValue
        : variant == .launch ? CGImageAlphaInfo.premultipliedLast.rawValue
        : CGImageAlphaInfo.noneSkipLast.rawValue
    guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info) else { return }

    let color: (UInt32) -> CGColor = variant == .tinted ? gray : { rgb($0) }

    // Background: mint for light, deep green-black for dark, black for tinted.
    switch variant {
    case .light: ctx.setFillColor(rgb(0xE9F5EA))
    case .dark: ctx.setFillColor(rgb(0x111815))
    case .tinted: ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    case .launch: ctx.setFillColor(CGColor(gray: 0, alpha: 0))   // transparent; the launch colour shows through
    }
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

    // Flip to a top-left origin and fit the 150 grid (content spans y 24...143) into the icon.
    ctx.translateBy(x: 0, y: CGFloat(size))
    ctx.scaleBy(x: 1, y: -1)
    // The icon leaves a margin; the launch image fills its square.
    let scale: CGFloat = CGFloat(size) / 1024 * (variant == .launch ? 8.4 : 5.6)
    let contentCenterY: CGFloat = (24 + 143) / 2
    ctx.translateBy(x: CGFloat(size) / 2 - 75 * scale, y: CGFloat(size) / 2 - contentCenterY * scale)
    ctx.scaleBy(x: scale, y: scale)

    // Stem
    ctx.setStrokeColor(color(variant == .dark ? 0x5DB761 : 0x2E7D32))
    ctx.setLineWidth(6)
    ctx.setLineCap(.round)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: 75, y: 92))
    ctx.addCurve(to: CGPoint(x: 75, y: 40), control1: CGPoint(x: 75, y: 70), control2: CGPoint(x: 75, y: 55))
    ctx.strokePath()

    // Leaves
    ctx.setFillColor(color(0x7CC97F)); leaf(ctx, [75, 78, 60, 80, 50, 72, 46, 60, 60, 58, 72, 64])
    ctx.setFillColor(color(0x66BB6A)); leaf(ctx, [75, 72, 90, 74, 100, 66, 104, 54, 90, 52, 78, 58])
    ctx.setFillColor(color(0x4CAF50)); leaf(ctx, [75, 62, 55, 62, 42, 50, 40, 34, 58, 34, 72, 44])
    ctx.setFillColor(color(0x4CAF50)); leaf(ctx, [75, 52, 95, 52, 108, 40, 110, 24, 92, 24, 78, 34])

    // Pot
    ctx.setFillColor(color(0xF0A04B))
    ctx.beginPath()
    ctx.move(to: CGPoint(x: 40, y: 92))
    ctx.addLine(to: CGPoint(x: 110, y: 92))
    ctx.addLine(to: CGPoint(x: 102, y: 138))
    ctx.addQuadCurve(to: CGPoint(x: 96, y: 143), control: CGPoint(x: 101, y: 143))
    ctx.addLine(to: CGPoint(x: 54, y: 143))
    ctx.addQuadCurve(to: CGPoint(x: 48, y: 138), control: CGPoint(x: 49, y: 143))
    ctx.closePath()
    ctx.fillPath()

    ctx.setFillColor(color(0xD9822B))
    ctx.addPath(CGPath(roundedRect: CGRect(x: 34, y: 86, width: 82, height: 14), cornerWidth: 7, cornerHeight: 7, transform: nil))
    ctx.fillPath()

    // Face
    ctx.setFillColor(color(0x3A2A1A))
    ctx.fillEllipse(in: CGRect(x: 58, y: 112, width: 8, height: 8))
    ctx.fillEllipse(in: CGRect(x: 84, y: 112, width: 8, height: 8))
    ctx.setStrokeColor(color(0x3A2A1A))
    ctx.setLineWidth(3)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: 66, y: 126))
    ctx.addQuadCurve(to: CGPoint(x: 84, y: 126), control: CGPoint(x: 75, y: 133))
    ctx.strokePath()

    guard let image = ctx.makeImage() else { return }
    let rep = NSBitmapImageRep(cgImage: image)
    try? rep.representation(using: .png, properties: [:])?.write(to: url)
}

let out = URL(fileURLWithPath: CommandLine.arguments[1])
render(.light, to: out.appendingPathComponent("AppIcon.png"))
render(.dark, to: out.appendingPathComponent("AppIcon-dark.png"))
render(.tinted, to: out.appendingPathComponent("AppIcon-tinted.png"))
// Launch screen sprout, 120 points square at 1x, 2x and 3x.
for (scale, suffix) in [(1, ""), (2, "@2x"), (3, "@3x")] {
    render(.launch, size: 120 * scale, to: out.appendingPathComponent("LaunchSprout\(suffix).png"))
}
print("rendered")
