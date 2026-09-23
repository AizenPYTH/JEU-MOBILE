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
}
