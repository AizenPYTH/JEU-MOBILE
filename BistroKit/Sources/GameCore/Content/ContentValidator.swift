import Foundation

/// A problem found in the content files. Content issues are bugs: tests fail on any of them.
public struct ContentIssue: Sendable, Hashable, CustomStringConvertible {
    public var file: String
    public var message: String

    public var description: String { "[\(file)] \(message)" }
}

/// Cross-checks content files against each other (unknown ids, duplicates, bad formats…).
public enum ContentValidator {
    /// Ids are lowercase snake_case so they map cleanly to asset names (`ing_tomato`).
    public static func isValidID(_ id: String) -> Bool {
        guard let first = id.unicodeScalars.first, ("a"..."z").contains(first) else { return false }
        return id.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "_" }
    }

    public static func validate(_ content: GameContent) -> [ContentIssue] {
        var issues: [ContentIssue] = []
        typealias F = ContentLoader.FileName

        func checkIDs(_ ids: [String], file: String) {
            var seen = Set<String>()
            for id in ids {
                if !isValidID(id) { issues.append(.init(file: file, message: "invalid id '\(id)' (use lowercase snake_case)")) }
                if !seen.insert(id).inserted { issues.append(.init(file: file, message: "duplicate id '\(id)'")) }
            }
        }

        checkIDs(content.ingredients.map(\.id), file: F.ingredients)
        checkIDs(content.stations.map(\.id), file: F.stations)
        checkIDs(content.recipes.map(\.id), file: F.recipes)
        checkIDs(content.regulars.map(\.id), file: F.regulars)
        checkIDs(content.zones.map(\.id), file: F.zones)
        checkIDs(content.decorations.map(\.id), file: F.decorations)

        let ingredientIDs = Set(content.ingredients.map(\.id))
        let stationIDs = Set(content.stations.map(\.id))
        let zoneIDs = Set(content.zones.map(\.id))
        var combinations: [String: RecipeID] = [:]

        for recipe in content.recipes {
            let r = "recipe '\(recipe.id)'"
            if !(2...3).contains(recipe.ingredients.count) {
                issues.append(.init(file: F.recipes, message: "\(r) must use 2 or 3 ingredients"))
            }
            if Set(recipe.ingredients).count != recipe.ingredients.count {
                issues.append(.init(file: F.recipes, message: "\(r) uses the same ingredient twice"))
            }
            for ing in recipe.ingredients where !ingredientIDs.contains(ing) {
                issues.append(.init(file: F.recipes, message: "\(r) uses unknown ingredient '\(ing)'"))
            }
            if !stationIDs.contains(recipe.station) {
                issues.append(.init(file: F.recipes, message: "\(r) uses unknown station '\(recipe.station)'"))
            }
            if recipe.basePrice <= 0 || recipe.prepSeconds <= 0 {
                issues.append(.init(file: F.recipes, message: "\(r) needs a positive price and prep time"))
            }
            if let other = combinations[recipe.combinationKey] {
                issues.append(.init(file: F.recipes, message: "\(r) has the same ingredients as '\(other)'"))
            } else {
                combinations[recipe.combinationKey] = recipe.id
            }
        }

        for regular in content.regulars {
            let overlap = Set(regular.likes).intersection(regular.dislikes)
            if !overlap.isEmpty {
                issues.append(.init(file: F.regulars, message: "regular '\(regular.id)' both likes and dislikes \(overlap.map(\.rawValue).sorted())"))
            }
        }

        for deco in content.decorations where !zoneIDs.contains(deco.zone) {
            issues.append(.init(file: F.decorations, message: "decoration '\(deco.id)' is in unknown zone '\(deco.zone)'"))
        }

        return issues
    }
}
