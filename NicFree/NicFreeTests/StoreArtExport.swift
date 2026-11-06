import SwiftUI
import Testing

@testable import NicFree

/// Renders the sprout's stages and a share card as PNGs for the App Store artwork.
/// Skipped in normal runs; `tools/store-art.sh` turns it on with an output folder.
@MainActor
@Suite("Store art")
struct StoreArtExport {

    private static let folder = ProcessInfo.processInfo.environment["ART_DIR"]

    private func write(_ view: some View, size: CGSize, scale: CGFloat, to name: String) throws {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height).environment(\.colorScheme, .light))
        renderer.scale = scale
        renderer.isOpaque = false
        let image = try #require(renderer.uiImage)
        let data = try #require(image.pngData())
        try data.write(to: URL(fileURLWithPath: Self.folder!).appendingPathComponent("\(name).png"))
    }

    @Test(.enabled(if: folder != nil))
    func exportArt() throws {
        for stage in Sprout.stages {
            try write(Sprout(freeDays: stage.day), size: CGSize(width: 300, height: 300), scale: 4, to: "sprout-\(stage.day)")
        }
        try write(Sprout(freeDays: 63, thirsty: true), size: CGSize(width: 300, height: 300), scale: 4, to: "sprout-thirsty")
        try write(ShareCard(moment: ShareMoment(days: 30, sproutDays: 30, milestone: 30)), size: ShareCard.size, scale: 3, to: "share-30")
        try write(ShareCard(moment: ShareMoment(days: 63, sproutDays: 63, milestone: nil)), size: ShareCard.size, scale: 3, to: "share-63")
    }
}
