import Foundation
import Testing
import CaseEngine

/// Every interface string used by ScreenshotUI exists in French and English.
/// Reads the String Catalog as JSON so it runs on Linux too.
@Suite("Interface localization")
struct LocalizationTests {
    static let uiSources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/ScreenshotUI")

    struct Catalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct Unit: Decodable { let value: String }
                struct Variant: Decodable { let stringUnit: Unit }
                struct Variations: Decodable { let plural: [String: Variant]? }
                let stringUnit: Unit?
                let variations: Variations?

                /// The plain string, or the "other" form of a plural (which must then also have "one").
                var text: String {
                    if let plural = variations?.plural {
                        return plural["one"] == nil ? "" : plural["other"]?.stringUnit.value ?? ""
                    }
                    return stringUnit?.value ?? ""
                }
            }
            let localizations: [String: Localization]?
        }
        let strings: [String: Entry]
    }

    @Test func everyKeyIsTranslated() throws {
        let catalogURL = Self.uiSources.appendingPathComponent("Resources/Localizable.xcstrings")
        let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: catalogURL))

        var keys = Set(AppID.allCases.map { "app.\($0.rawValue)" } + SuspectMark.allCases.map { "mark.\($0.rawValue)" })
        let regex = try NSRegularExpression(pattern: #"L10n\.(?:t|f)\("([A-Za-z0-9_.]+)""#)
        let files = FileManager.default.enumerator(at: Self.uiSources, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" } ?? []
        #expect(files.count > 10)
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let r = Range(match.range(at: 1), in: text) { keys.insert(String(text[r])) }
            }
        }
        var missing: [String] = []
        for key in keys.sorted() {
            for lang in ["fr", "en"] where (catalog.strings[key]?.localizations?[lang]?.text ?? "").isEmpty {
                missing.append("\(key) [\(lang)]")
            }
        }
        #expect(missing.isEmpty, "Missing translations:\n\(missing.joined(separator: "\n"))")
    }

    /// Final handoff, acceptance criterion 4 and the game's identity: the three verbs are EXPLORER ·
    /// VERSER AU DOSSIER · CONCLURE. « Épingler », « Accuser » (the link label « L'ACCUSE » aside),
    /// « Recrue », « Stagiaire » and the old working names never reach the player.
    @Test func bannedWordsAreGone() throws {
        let catalogURL = Self.uiSources.appendingPathComponent("Resources/Localizable.xcstrings")
        let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: catalogURL))
        let banned = try NSRegularExpression(
            pattern: #"(?i)(?<![\p{L}'’])(épingl\p{L}*|pin(?:ned|ning)?|accuser|accusez|accusation|accuse (?:now|a suspect)|recrue\p{L}*|recruit\p{L}*|stagiaire\p{L}*|trainee\p{L}*|trace|moonwolf)(?![\p{L}])"#)
        var findings: [String] = []
        for (key, entry) in catalog.strings {
            for (lang, localization) in entry.localizations ?? [:] {
                var values = [localization.stringUnit?.value]
                values += (localization.variations?.plural ?? [:]).values.map { $0.stringUnit.value }
                for value in values.compactMap({ $0 }) {
                    let range = NSRange(value.startIndex..., in: value)
                    if let match = banned.firstMatch(in: value, range: range), let r = Range(match.range, in: value) {
                        findings.append("\(key) [\(lang)]: « \(value[r]) » in « \(value) »")
                    }
                }
            }
        }
        #expect(findings.isEmpty, "Banned words:\n\(findings.sorted().joined(separator: "\n"))")
    }

    /// Xcode generates a Swift symbol per key by dropping the separators ("carnet.empty.title" and
    /// "carnet.emptyTitle" both give `carnetEmptyTitle`): two such keys stop the iOS build.
    @Test func keysGenerateDistinctSymbols() throws {
        let catalogURL = Self.uiSources.appendingPathComponent("Resources/Localizable.xcstrings")
        let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: catalogURL))
        var bySymbol: [String: [String]] = [:]
        for key in catalog.strings.keys {
            let symbol = String(key.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }).lowercased()
            bySymbol[symbol, default: []].append(key)
        }
        let clashes = bySymbol.values.filter { $0.count > 1 }.map { $0.sorted().joined(separator: " / ") }.sorted()
        #expect(clashes.isEmpty, "Keys generating the same symbol:\n\(clashes.joined(separator: "\n"))")
    }
}
