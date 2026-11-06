//
//  WidgetSnapshot.swift
//  NicFree
//

import Foundation

/// The little the widget needs to draw the sprout and the total, copied out of the store.
///
/// The widget reads this rather than the SwiftData store, so the store never has to move
/// into a shared container (rule 10: never risk anyone's history for a feature). Both
/// targets compile this file; the widget works out today's numbers from it with `QuitStats`.
struct WidgetSnapshot: Codable, Equatable {
    var quitStartedAt: Date
    var usedDays: [Date]

    private static let key = "widgetSnapshot"

    /// The App Group, from `NicFreeAppGroup` in Info.plist. Debug and Release builds use
    /// different groups so the two apps on one phone never share a widget.
    static var defaults: UserDefaults? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "NicFreeAppGroup") as? String,
              !group.isEmpty else { return nil }
        return UserDefaults(suiteName: group)
    }

    static func load() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// True when something changed, so the caller knows to reload the widget.
    @discardableResult
    func save() -> Bool {
        guard Self.load() != self, let data = try? JSONEncoder().encode(self) else { return false }
        Self.defaults?.set(data, forKey: Self.key)
        return true
    }

    func stats(on today: Date = Date()) -> QuitStats {
        QuitStats(quitStartedAt: quitStartedAt, usedDays: Set(usedDays), today: today)
    }
}
