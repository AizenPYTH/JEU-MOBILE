import Foundation
@testable import GameCore

/// Small hand-made content + config so engine tests don't depend on balance tuning.
enum Fixtures {
    static let content = GameContent(
        ingredients: [
            Ingredient(id: "egg", categories: [.savory], unlockLevel: 1),
            Ingredient(id: "cheese", categories: [.savory], unlockLevel: 1),
            Ingredient(id: "bread", categories: [.savory], unlockLevel: 1),
            Ingredient(id: "tomato", categories: [.savory], unlockLevel: 1),
            Ingredient(id: "honey", categories: [.sweet], unlockLevel: 1),
            Ingredient(id: "lemon", categories: [.sweet], unlockLevel: 1),
        ],
        stations: [Station(id: "stove", unlockLevel: 1), Station(id: "oven", unlockLevel: 1),
                   Station(id: "drinks_bar", unlockLevel: 2)],
        recipes: [
            Recipe(id: "omelette", ingredients: ["egg", "cheese"], station: "stove",
                   categories: [.savory], basePrice: 10, prepSeconds: 4),
            Recipe(id: "bruschetta", ingredients: ["tomato", "bread"], station: "oven",
                   categories: [.savory], basePrice: 8, prepSeconds: 5),
            Recipe(id: "honey_lemonade", ingredients: ["honey", "lemon"], station: "drinks_bar",
                   categories: [.sweet], basePrice: 5, prepSeconds: 2),
        ]
    )

    static func economy(_ edit: (inout EconomyConfig) -> Void = { _ in }) -> EconomyConfig {
        var e = EconomyConfig(
            schemaVersion: 1, startingCoins: 50, startingTables: 3,
            startingStations: ["stove", "oven"], startingRecipes: ["omelette"], startingMenuSlots: 2,
            customerSpawnIntervalSeconds: 5, customerSpawnJitterSeconds: 0, orderDelaySeconds: 1,
            eatSeconds: 3, waiterDeliverySeconds: 1, priceMultiplier: 1, prepTimeMultiplier: 1,
            baseTipFraction: 0.2, tipDecaySeconds: 20, autoCollectDelaySeconds: 10, tapBoostSeconds: 1,
            simulationStepSeconds: 0.25, maxCatchUpSeconds: 3_600, autosaveIntervalSeconds: 30)
        edit(&e)
        return e
    }

    static func config(_ edit: (inout EconomyConfig) -> Void = { _ in }) -> GameConfig {
        GameConfig(economy: economy(edit), lab: LabConfig(schemaVersion: 1), affinity: AffinityConfig(schemaVersion: 1),
                   progression: ProgressionConfig(schemaVersion: 1), offline: OfflineConfig(schemaVersion: 1),
                   ads: AdsConfig(schemaVersion: 1))
    }

    static func game(seed: UInt64 = 42, _ edit: (inout EconomyConfig) -> Void = { _ in }) -> (Game, ManualClock) {
        let clock = ManualClock(start: Date(timeIntervalSince1970: 1_700_000_000))
        return (Game(content: content, config: config(edit), clock: clock, seed: seed), clock)
    }
}
