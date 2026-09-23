/// Fast id → item lookups over `GameContent`.
public struct ContentIndex: Sendable {
    public let content: GameContent
    public let recipes: [RecipeID: Recipe]
    public let stations: [StationID: Station]
    public let ingredients: [IngredientID: Ingredient]

    public init(_ content: GameContent) {
        self.content = content
        recipes = Dictionary(content.recipes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        stations = Dictionary(content.stations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        ingredients = Dictionary(content.ingredients.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
