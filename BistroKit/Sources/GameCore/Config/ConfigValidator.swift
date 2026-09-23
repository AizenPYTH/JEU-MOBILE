/// Checks that the balance config is coherent with the content (ids exist, values are sane).
public enum ConfigValidator {
    public static func validate(_ config: GameConfig, content: GameContent) -> [ContentIssue] {
        var issues: [ContentIssue] = []
        let file = ConfigLoader.FileName.economy
        let e = config.economy
        let recipes = Dictionary(content.recipes.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let stations = Set(content.stations.map(\.id))

        func check(_ condition: Bool, _ message: String) {
            if !condition { issues.append(ContentIssue(file: file, message: message)) }
        }

        for id in e.startingStations { check(stations.contains(id), "unknown starting station '\(id)'") }
        for id in e.startingRecipes {
            guard let recipe = recipes[id] else { check(false, "unknown starting recipe '\(id)'"); continue }
            check(e.startingStations.contains(recipe.station),
                  "starting recipe '\(id)' needs station '\(recipe.station)' which is not a starting station")
        }
        check(!e.startingRecipes.isEmpty, "startingRecipes must not be empty")
        check(e.startingTables >= 1, "startingTables must be >= 1")
        check(e.startingMenuSlots >= 1, "startingMenuSlots must be >= 1")
        check(e.startingCoins >= 0, "startingCoins must be >= 0")
        check(e.customerSpawnIntervalSeconds > 0, "customerSpawnIntervalSeconds must be > 0")
        check(e.customerSpawnJitterSeconds >= 0, "customerSpawnJitterSeconds must be >= 0")
        check(e.eatSeconds >= 0 && e.orderDelaySeconds >= 0 && e.waiterDeliverySeconds >= 0, "durations must be >= 0")
        check(e.priceMultiplier > 0 && e.prepTimeMultiplier > 0, "multipliers must be > 0")
        check((0...1).contains(e.baseTipFraction), "baseTipFraction must be between 0 and 1")
        check(e.simulationStepSeconds > 0 && e.simulationStepSeconds <= 1, "simulationStepSeconds must be in (0, 1]")
        check(e.maxCatchUpSeconds >= 0, "maxCatchUpSeconds must be >= 0")
        check(e.autosaveIntervalSeconds > 0, "autosaveIntervalSeconds must be > 0")
        return issues
    }
}
