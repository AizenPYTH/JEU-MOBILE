import Foundation

// Content = *what exists* in the game (ingredients, dishes, characters…).
// Identifiers are shared with the design team: never rename one without updating
// HANDOFF_INTEGRATION.md and the asset catalog.
//
// Display names and texts are NOT stored here. They live in the String Catalog under
// keys derived from the id (see `LocalizationKey`).

public typealias IngredientID = String
public typealias RecipeID = String
public typealias StationID = String
public typealias RegularID = String
public typealias ZoneID = String
public typealias DecorationID = String

/// Flavour / type tags used by recipes, regulars' tastes and lab hints.
public enum DishCategory: String, Codable, Sendable, CaseIterable, Hashable {
    case sweet, savory, spicy, vegetarian, fish, comfort, rare, quick, drink
}

public struct Ingredient: Codable, Sendable, Hashable, Identifiable {
    public var id: IngredientID
    public var categories: [DishCategory]
    /// Reputation level at which the ingredient becomes available.
    public var unlockLevel: Int

    public init(id: IngredientID, categories: [DishCategory], unlockLevel: Int) {
        self.id = id
        self.categories = categories
        self.unlockLevel = unlockLevel
    }
}

public struct Station: Codable, Sendable, Hashable, Identifiable {
    public var id: StationID
    public var unlockLevel: Int

    public init(id: StationID, unlockLevel: Int) {
        self.id = id
        self.unlockLevel = unlockLevel
    }
}

public struct Recipe: Codable, Sendable, Hashable, Identifiable {
    public var id: RecipeID
    /// 2 or 3 ingredient ids. Order does not matter.
    public var ingredients: [IngredientID]
    public var station: StationID
    public var categories: [DishCategory]
    /// Base sale price in coins (tunable here; global multipliers live in the balance config).
    public var basePrice: Int
    /// Base preparation time in seconds.
    public var prepSeconds: Double

    public init(
        id: RecipeID, ingredients: [IngredientID], station: StationID,
        categories: [DishCategory], basePrice: Int, prepSeconds: Double
    ) {
        self.id = id
        self.ingredients = ingredients
        self.station = station
        self.categories = categories
        self.basePrice = basePrice
        self.prepSeconds = prepSeconds
    }

    /// Order-independent key used to look a combination up in the lab.
    public var combinationKey: String { Recipe.combinationKey(ingredients) }

    public static func combinationKey(_ ingredients: [IngredientID]) -> String {
        ingredients.sorted().joined(separator: "+")
    }
}

public struct Regular: Codable, Sendable, Hashable, Identifiable {
    public var id: RegularID
    public var likes: [DishCategory]
    public var dislikes: [DishCategory]

    public init(id: RegularID, likes: [DishCategory], dislikes: [DishCategory]) {
        self.id = id
        self.likes = likes
        self.dislikes = dislikes
    }
}

public struct Zone: Codable, Sendable, Hashable, Identifiable {
    public var id: ZoneID
    public var unlockLevel: Int

    public init(id: ZoneID, unlockLevel: Int) {
        self.id = id
        self.unlockLevel = unlockLevel
    }
}

public struct Decoration: Codable, Sendable, Hashable, Identifiable {
    public var id: DecorationID
    public var zone: ZoneID

    public init(id: DecorationID, zone: ZoneID) {
        self.id = id
        self.zone = zone
    }
}

/// Every content file shares this envelope: `{ "schemaVersion": 1, "items": [...] }`.
public struct ContentFile<Item: Codable & Sendable>: Codable, Sendable {
    public var schemaVersion: Int
    public var items: [Item]
}

/// All static game content, loaded once at startup.
public struct GameContent: Sendable {
    public var ingredients: [Ingredient]
    public var stations: [Station]
    public var recipes: [Recipe]
    public var regulars: [Regular]
    public var zones: [Zone]
    public var decorations: [Decoration]

    public init(
        ingredients: [Ingredient] = [], stations: [Station] = [], recipes: [Recipe] = [],
        regulars: [Regular] = [], zones: [Zone] = [], decorations: [Decoration] = []
    ) {
        self.ingredients = ingredients
        self.stations = stations
        self.recipes = recipes
        self.regulars = regulars
        self.zones = zones
        self.decorations = decorations
    }
}
