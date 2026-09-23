import Testing
@testable import GameCore

@Suite("ContentValidator")
struct ContentValidatorTests {
    private let base = GameContent(
        ingredients: [
            Ingredient(id: "tomato", categories: [.savory], unlockLevel: 1),
            Ingredient(id: "bread", categories: [.savory], unlockLevel: 1),
        ],
        stations: [Station(id: "oven", unlockLevel: 1)],
        recipes: [
            Recipe(id: "bruschetta", ingredients: ["tomato", "bread"], station: "oven",
                   categories: [.savory], basePrice: 8, prepSeconds: 6),
        ]
    )

    @Test func validContentHasNoIssues() {
        #expect(ContentValidator.validate(base).isEmpty)
    }

    @Test(arguments: ["tomato", "cutting_board", "lv2_oven"])
    func acceptsSnakeCaseIDs(_ id: String) {
        #expect(ContentValidator.isValidID(id))
    }

    @Test(arguments: ["", "Tomato", "2tomato", "tomato-soup", "tomato soup", "_x"])
    func rejectsBadIDs(_ id: String) {
        #expect(!ContentValidator.isValidID(id))
    }

    @Test func detectsUnknownReferences() {
        var content = base
        content.recipes.append(Recipe(id: "mystery", ingredients: ["tomato", "unicorn"], station: "laser",
                                      categories: [], basePrice: 1, prepSeconds: 1))
        let messages = ContentValidator.validate(content).map(\.message)
        #expect(messages.contains { $0.contains("unknown ingredient 'unicorn'") })
        #expect(messages.contains { $0.contains("unknown station 'laser'") })
    }

    @Test func detectsDuplicateCombinationsRegardlessOfOrder() {
        var content = base
        content.recipes.append(Recipe(id: "toast", ingredients: ["bread", "tomato"], station: "oven",
                                      categories: [], basePrice: 1, prepSeconds: 1))
        #expect(ContentValidator.validate(content).contains { $0.message.contains("same ingredients") })
    }

    @Test func detectsDuplicateIDs() {
        var content = base
        content.ingredients.append(Ingredient(id: "tomato", categories: [], unlockLevel: 1))
        #expect(ContentValidator.validate(content).contains { $0.message.contains("duplicate id 'tomato'") })
    }

    @Test func combinationKeyIsOrderIndependent() {
        #expect(Recipe.combinationKey(["tomato", "bread"]) == Recipe.combinationKey(["bread", "tomato"]))
    }
}
