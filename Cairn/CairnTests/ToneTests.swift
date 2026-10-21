import Foundation
import Testing

/// Product rule 3 as a test: no shaming language reaches the app.
///
/// Scans every string literal in the app's Swift source, and every key and English value
/// in the String Catalog. Comments are skipped, because the code explains these rules in
/// exactly these words.
@Suite("Tone")
struct ToneTests {

    /// Relapse is banned as a verb only, so "relapse" alone is allowed.
    private static let banned = #"\b(fail|fails|failed|failing|failure|broke|broken|lost|lose|streak|streaks|start over|relapsed|relapsing)\b"#

    private static let appSource: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Cairn")

    private func matches(in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: Self.banned, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }

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
                    let found = matches(in: String(code[r]))
                    if !found.isEmpty {
                        offences.append("\(file.lastPathComponent):\(number + 1) \(found)")
                    }
                }
            }
        }
        #expect(offences.isEmpty, "Shaming words in user-facing strings: \(offences)")
    }

    @Test("String Catalog uses no banned words")
    func catalog() throws {
        let url = Self.appSource.appendingPathComponent("Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(json["strings"] as? [String: Any])

        var offences: [String] = []
        for (key, entry) in strings {
            var texts = [key]
            if let entry = entry as? [String: Any],
               let localizations = entry["localizations"] as? [String: Any],
               let english = localizations["en"] as? [String: Any],
               let unit = english["stringUnit"] as? [String: Any],
               let value = unit["value"] as? String {
                texts.append(value)
            }
            for text in texts where !matches(in: text).isEmpty {
                offences.append(text)
            }
        }
        #expect(offences.isEmpty, "Shaming words in the String Catalog: \(offences)")
    }
}
