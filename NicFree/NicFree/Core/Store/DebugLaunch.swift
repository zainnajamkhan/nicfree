//
//  DebugLaunch.swift
//  NicFree
//

#if DEBUG
import Foundation

/// Debug builds only, so the dev app can be walked from the very first screen on every
/// launch without reinstalling.
enum DebugLaunch {
    static let key = "debugStartFresh"

    /// On unless switched off in Settings. While on, each launch uses an empty temporary
    /// store (the saved one is left alone) and starts with the unlock off, exactly like a
    /// first launch: onboarding, then the paywall.
    static var startFresh: Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }
}
#endif
