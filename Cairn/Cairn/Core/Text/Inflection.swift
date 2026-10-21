//
//  Inflection.swift
//  Cairn
//

import Foundation

extension String {
    /// A localized string with Foundation's automatic grammar agreement applied, so
    /// `"^[\(n) free day](inflect: true)"` reads "1 free day" and "2 free days", and the
    /// same key can be translated with the right plural rules later.
    init(inflecting key: String.LocalizationValue) {
        self = String(AttributedString(localized: key).characters)
    }
}
