import Foundation
import Testing
import GameCore
import GameData

/// The design sketches (BistroUI/Resources/Sketches.xcassets) are the placeholder art until the
/// final illustrations arrive. They must follow the naming convention and cover current content.
@Suite("Design sketches")
struct SketchCoverageTests {
    static var catalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/BistroUI/Resources/Sketches.xcassets")
    }

    static func sketchNames() throws -> Set<String> {
        let items = try FileManager.default.contentsOfDirectory(atPath: catalogURL.path)
        return Set(items.filter { $0.hasSuffix(".imageset") }.map { String($0.dropLast(".imageset".count)) })
    }

    @Test func namesFollowTheConvention() throws {
        let prefixes = ["ing_", "dish_", "char_", "staff_", "station_", "deco_", "bg_", "ui_", "currency_"]
        for name in try Self.sketchNames() {
            #expect(prefixes.contains { name.hasPrefix($0) }, "\(name) does not follow the asset naming convention")
        }
    }

    @Test func currentContentHasSketches() throws {
        let names = try Self.sketchNames()
        let content = try GameData.loadContent()
        var expected: [String] = []
        expected += content.ingredients.map { AssetName.ingredient($0.id) }
        expected += content.recipes.map { AssetName.dish($0.id) }
        expected += content.regulars.flatMap { r in AssetName.CharacterPose.allCases.map { AssetName.character(r.id, $0) } }
        expected += content.stations.flatMap { s in (1...3).map { AssetName.station(s.id, level: $0) } }
        expected += AssetName.StaffRole.allCases.flatMap { r in AssetName.StaffPose.allCases.map { AssetName.staff(r, $0) } }
        let missing = expected.filter { !names.contains($0) }
        #expect(missing.isEmpty, "No sketch for: \(missing.joined(separator: ", "))")
    }
}
