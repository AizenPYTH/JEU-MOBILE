import Foundation
import GameCore
import GameData

// Balance simulator. For now (M0) it only loads and validates the data files.
// M6 turns it into a full "typical player" simulation over 1, 7 and 30 days.
//
// Usage: swift run BalanceSim

do {
    let content = try GameData.loadContent()
    _ = try GameData.loadConfig()
    let issues = ContentValidator.validate(content)

    print("Bistro BalanceSim – GameCore \(GameCore.version)")
    print("  ingredients: \(content.ingredients.count)")
    print("  stations:    \(content.stations.count)")
    print("  recipes:     \(content.recipes.count)")
    print("  regulars:    \(content.regulars.count)")
    print("  zones:       \(content.zones.count)")
    print("  decorations: \(content.decorations.count)")

    if issues.isEmpty {
        print("Content OK.")
    } else {
        print("Content issues:")
        issues.forEach { print("  - \($0)") }
        exit(1)
    }
} catch {
    print("Failed to load data: \(error)")
    exit(1)
}
