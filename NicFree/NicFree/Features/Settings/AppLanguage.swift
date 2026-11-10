//
//  AppLanguage.swift
//  NicFree
//

import Foundation

/// The app's own language, which can differ from the iPhone's.
///
/// Writes the same `AppleLanguages` key that iPhone Settings → NicFree → Language writes, so
/// the two always agree. iOS reads it at launch, so a change shows the next time the app
/// opens. The in-app picker exists because iOS hides that row in Settings unless the iPhone
/// already has more than one language added. The widget follows the iPhone's language.
enum AppLanguage {
    /// Every language the app ships in, in the order the picker lists them.
    static let codes = ["en", "sv", "de", "es", "fr", "ar"]

    private static let key = "AppleLanguages"

    /// The language picked for NicFree, or nil when it follows the iPhone. Only the app's
    /// own defaults count: the iPhone's list is in the global domain.
    static var chosen: String? {
        get {
            guard let id = Bundle.main.bundleIdentifier,
                  let list = UserDefaults.standard.persistentDomain(forName: id)?[key] as? [String],
                  let first = list.first
            else { return nil }
            return Locale(identifier: first).language.languageCode?.identifier ?? first
        }
        set {
            if let newValue {
                UserDefaults.standard.set([newValue], forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    /// The language on screen now.
    static var showing: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }

    /// The language the app will open in next time, given what is saved now.
    static var nextLaunch: String {
        let preferences = UserDefaults.standard.stringArray(forKey: key) ?? Locale.preferredLanguages
        return Bundle.preferredLocalizations(from: codes, forPreferences: preferences).first ?? "en"
    }

    /// A language's name in that language ("Deutsch", "العربية"), the way iOS lists them, so
    /// someone can find their own language however the app is set.
    static func name(of code: String) -> String {
        let locale = Locale(identifier: code)
        return (locale.localizedString(forLanguageCode: code) ?? code).capitalized(with: locale)
    }
}
