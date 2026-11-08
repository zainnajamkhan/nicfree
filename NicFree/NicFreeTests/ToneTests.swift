import Foundation
import Testing

/// Product rule 3 as a test: no shaming language reaches the app.
///
/// Scans every string literal in the app's Swift source, and every key and every translation
/// in both String Catalogs, against a banned list per language. Comments are skipped, because the code explains these rules in
/// exactly these words.
@Suite("Tone")
struct ToneTests {

    /// Relapse is banned as a verb only, so "relapse" alone is allowed.
    private static let banned = #"\b(fail|fails|failed|failing|failure|broke|broken|lost|lose|streak|streaks|start over|relapsed|relapsing)\b"#

    private static let appSource: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("NicFree")

    @Test("Swift string literals use no banned words")
    func swiftLiterals() throws {
        let files = FileManager.default.enumerator(at: Self.appSource, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" } ?? []
        #expect(!files.isEmpty, "Found no Swift files at \(Self.appSource.path)")

        let literal = try NSRegularExpression(pattern: #""(?:[^"\\]|\\.)*""#)
        var offences: [String] = []

        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            for (number, line) in source.components(separatedBy: .newlines).enumerated() {
                let code = line.components(separatedBy: "//").first ?? line
                let range = NSRange(code.startIndex..., in: code)
                for match in literal.matches(in: code, range: range) {
                    guard let r = Range(match.range, in: code) else { continue }
                    let found = matches(in: String(code[r]), language: "en")
                    if !found.isEmpty {
                        offences.append("\(file.lastPathComponent):\(number + 1) \(found)")
                    }
                }
            }
        }
        #expect(offences.isEmpty, "Shaming words in user-facing strings: \(offences)")
    }

    /// The same rule in each shipped language: fail, lose, streak, start over, relapse as a verb.
    /// Arabic has no word boundaries the regex understands, so its words match anywhere.
    private static let bannedByLanguage: [String: String] = [
        "sv": #"\b(misslyck\w*|förlor\w*|svit\w*|börja om|återföll|återfalla\w*|sumpa\w*)\b"#,
        "de": #"\b(versag\w*|scheiter\w*|gescheitert|verlor\w*|verlier\w*|serie|strähne|von vorn|neu anfangen|rückfällig\w*)\b"#,
        "es": #"\b(fall(ar|aste|aste|ó|aron|ido|o)|fracas\w*|perd\w*|pierd\w*|racha\w*|empezar de cero|volver a empezar|reca(er|íste|yó|yeron|ído))\b"#,
        "fr": #"\b(échou\w*|échec\w*|perd\w*|série\w*|recommencer à zéro|repartir de zéro|rechut(er|é|es|ez))\b"#,
        "ar": #"(فشل|خسر|سلسلة|من الصفر|ابدأ من جديد|انتكس)"#,
    ]

    private func matches(in text: String, language: String) -> [String] {
        let pattern = language == "en" ? Self.banned : (Self.bannedByLanguage[language] ?? Self.banned)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }

    /// Every value in a localization: the plain string, or each plural form.
    private func values(in localization: Any) -> [String] {
        guard let localization = localization as? [String: Any] else { return [] }
        var found: [String] = []
        if let unit = localization["stringUnit"] as? [String: Any], let value = unit["value"] as? String {
            found.append(value)
        }
        if let variations = localization["variations"] as? [String: Any] {
            for case let forms as [String: Any] in variations.values {
                for form in forms.values { found += values(in: form) }
            }
        }
        return found
    }

    @Test("String Catalogs use no banned words, in any language", arguments: [
        "NicFree/Resources/Localizable.xcstrings", "NicFreeWidget/Localizable.xcstrings",
    ])
    func catalog(path: String) throws {
        let url = Self.appSource.deletingLastPathComponent().appendingPathComponent(path)
        let data = try Data(contentsOf: url)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(json["strings"] as? [String: Any])

        var offences: [String] = []
        var languages: Set<String> = []
        for (key, entry) in strings {
            offences += matches(in: key, language: "en").map { "en \(key): \($0)" }
            guard let entry = entry as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any] else { continue }
            for (language, localization) in localizations {
                languages.insert(language)
                for text in values(in: localization) {
                    offences += matches(in: text, language: language).map { "\(language) \(text): \($0)" }
                }
            }
        }
        #expect(languages.isSuperset(of: ["sv", "de", "es", "fr", "ar"]), "Missing languages: \(languages)")
        #expect(offences.isEmpty, "Shaming words in \(path): \(offences)")
    }
}
