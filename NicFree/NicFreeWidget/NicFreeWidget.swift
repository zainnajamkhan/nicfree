//
//  NicFreeWidget.swift
//  NicFreeWidget
//

import SwiftUI
import WidgetKit

/// The sprout and the total, on the Home Screen and the Lock Screen.
///
/// Reads the snapshot the app writes, never the store. The numbers are worked out for each
/// entry's own date, so the count moves on at midnight without the app being opened.
@main
struct NicFreeWidgetBundle: WidgetBundle {
    var body: some Widget {
        SproutWidget()
    }
}

struct SproutWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SproutWidget", provider: Provider()) { entry in
            SproutWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    // Soft sun into leaf in light mode, a deep green in dark mode, so the
                    // text on top always has the contrast of the app's own screens.
                    LinearGradient(
                        colors: [Color(light: 0xFFF4D6, dark: 0x1E3326), Color(light: 0xE9F5EA, dark: 0x14211A)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Your sprout")
        .description("Your free days, and the sprout they're growing.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Timeline

struct Entry: TimelineEntry {
    let date: Date
    /// Nil before onboarding: the widget then just invites them in.
    let free: Int?
    let finished: Int
    let thirsty: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), free: 12, finished: 11, thirsty: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry(on: Date()))
    }

    /// Now, then each of the next few midnights, so the count turns over on its own.
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        var dates = [now]
        for offset in 1...3 {
            if let midnight = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) {
                dates.append(midnight)
            }
        }
        completion(Timeline(entries: dates.map(entry(on:)), policy: .atEnd))
    }

    private func entry(on date: Date) -> Entry {
        guard let snapshot = WidgetSnapshot.load() else {
            return Entry(date: date, free: nil, finished: 0, thirsty: false)
        }
        let stats = snapshot.stats(on: date)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let used = Set(snapshot.usedDays)
        return Entry(
            date: date,
            free: stats.lifetimeFreeDays,
            finished: stats.finishedFreeDays,
            thirsty: used.contains(today) || used.contains(yesterday)
        )
    }
}

// MARK: - Views

struct SproutWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: Entry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        case .systemMedium: medium
        default: small
        }
    }

    private var number: String { (entry.free ?? 0).formatted() }

    private var daysLabel: String {
        entry.free == 1 ? String(localized: "free day") : String(localized: "free days")
    }

    private var small: some View {
        VStack(spacing: 2) {
            Sprout(freeDays: entry.finished, thirsty: entry.thirsty)
                .frame(maxHeight: .infinity)
            if entry.free != nil {
                Text(number)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.accent)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(daysLabel)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.inkSoft)
            } else {
                Text("Open NicFree to start")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var medium: some View {
        HStack(spacing: 14) {
            Sprout(freeDays: entry.finished, thirsty: entry.thirsty)
            VStack(alignment: .leading, spacing: 4) {
                if entry.free != nil {
                    Text(number)
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.accent)
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(daysLabel)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text(Sprout.stages[Sprout.stageIndex(freeDays: entry.finished)].name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.inkSoft)
                } else {
                    Text("Open NicFree to start")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Lock Screen: the system tints it, so it's shapes and numbers only.
    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(number)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding(4)
        }
        .widgetAccentable()
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.fill")
                .font(.title3.weight(.bold))
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 0) {
                Text(number)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                Text(daysLabel)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            Spacer(minLength: 0)
        }
    }

    private var inline: some View {
        Label("\(number) \(daysLabel)", systemImage: "leaf.fill")
    }
}

#Preview(as: .systemSmall) {
    SproutWidget()
} timeline: {
    Entry(date: .now, free: 31, finished: 30, thirsty: false)
    Entry(date: .now, free: 64, finished: 63, thirsty: true)
}
