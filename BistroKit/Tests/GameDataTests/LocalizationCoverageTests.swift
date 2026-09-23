import Foundation
import Testing
import GameCore
import GameData

/// Every content id must have a name in every shipped language.
/// Reads the String Catalog as plain JSON so it also runs on Linux.
@Suite("Localization coverage")
struct LocalizationCoverageTests {
    static let languages = ["en", "fr"]

    static var catalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/BistroUI/Resources/Localizable.xcstrings")
    }

    struct Catalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct Unit: Decodable { let value: String }
                let stringUnit: Unit?
            }
            let localizations: [String: Localization]?
        }
        let strings: [String: Entry]
    }

    @Test func everyContentKeyIsTranslated() throws {
        let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: Self.catalogURL))
        let content = try GameData.loadContent()

        var keys: [String] = []
        keys += content.ingredients.map { LocalizationKey.ingredientName($0.id) }
        keys += content.recipes.map { LocalizationKey.dishName($0.id) }
        keys += content.stations.map { LocalizationKey.stationName($0.id) }
        keys += content.regulars.map { LocalizationKey.regularName($0.id) }
        keys += content.zones.map { LocalizationKey.zoneName($0.id) }
        keys += content.decorations.map { LocalizationKey.decorationName($0.id) }
        keys += DishCategory.allCases.map { LocalizationKey.category($0) }

        var missing: [String] = []
        for key in keys {
            for lang in Self.languages {
                let value = catalog.strings[key]?.localizations?[lang]?.stringUnit?.value ?? ""
                if value.isEmpty { missing.append("\(key) [\(lang)]") }
            }
        }
        #expect(missing.isEmpty, "Missing translations:\n\(missing.joined(separator: "\n"))")
    }
}
