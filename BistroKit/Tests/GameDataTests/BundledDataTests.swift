import Testing
import GameCore
import GameData

/// Guards the real JSON files shipped with the game. If you edit content or balance files,
/// run `swift test` – these tests tell you exactly what is wrong.
@Suite("Bundled data")
struct BundledDataTests {
    @Test func contentLoadsAndIsValid() throws {
        let content = try GameData.loadContent()
        let issues = ContentValidator.validate(content)
        #expect(issues.isEmpty, "\(issues.map(\.description).joined(separator: "\n"))")
    }

    @Test func configLoads() throws {
        _ = try GameData.loadConfig()
    }

    /// Ids shared with the design team (HANDOFF_INTEGRATION.md). Removing one is a breaking change.
    @Test func mvpIdentifiersArePresent() throws {
        let content = try GameData.loadContent()
        let ingredients = Set(content.ingredients.map(\.id))
        for id in ["tomato", "cheese", "bread", "egg", "rice", "noodles", "chicken", "fish", "chili", "basil", "lemon", "honey"] {
            #expect(ingredients.contains(id), "missing ingredient \(id)")
        }
        let regulars = Set(content.regulars.map(\.id))
        for id in ["margot", "tomas", "mei", "leon", "priya", "oscar"] {
            #expect(regulars.contains(id), "missing regular \(id)")
        }
        let stations = Set(content.stations.map(\.id))
        for id in ["stove", "oven", "cutting_board", "drinks_bar"] {
            #expect(stations.contains(id), "missing station \(id)")
        }
    }
}
