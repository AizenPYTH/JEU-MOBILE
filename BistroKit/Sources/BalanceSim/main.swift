import Foundation
import GameCore
import GameData

// Balance simulator. For now (M1) it validates the data files and runs one idle hour.
// M6 turns it into a full "typical player" simulation over 1, 7 and 30 days.
//
// Usage: swift run BalanceSim

do {
    let content = try GameData.loadContent()
    let config = try GameData.loadConfig()
    let issues = ContentValidator.validate(content) + ConfigValidator.validate(config, content: content)

    print("Bistro BalanceSim – GameCore \(GameCore.version)")
    print("  ingredients: \(content.ingredients.count)")
    print("  stations:    \(content.stations.count)")
    print("  recipes:     \(content.recipes.count)")
    print("  regulars:    \(content.regulars.count)")
    print("  zones:       \(content.zones.count)")
    print("  decorations: \(content.decorations.count)")

    if issues.isEmpty {
        print("Content OK.")
        let game = Game(content: content, config: config, clock: ManualClock(), seed: 1)
        game.simulate(seconds: 3_600)
        let stats = game.state.stats
        print("\nOne idle hour (no taps, auto-collect only):")
        print("  customers served: \(stats.customersServed)")
        print("  coins earned:     \(stats.coinsEarned) (tips \(stats.tipsEarned))")
        print("  coins per minute: \(stats.coinsEarned / 60)")
        print("  dishes:           \(stats.dishesServed.sorted { $0.key < $1.key }.map { "\($0.key)×\($0.value)" }.joined(separator: ", "))")
    } else {
        print("Content issues:")
        issues.forEach { print("  - \($0)") }
        exit(1)
    }
} catch {
    print("Failed to load data: \(error)")
    exit(1)
}
