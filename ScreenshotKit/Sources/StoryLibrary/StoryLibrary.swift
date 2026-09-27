import Foundation
import StoryEngine

/// The story shipped with the game (JSON in `Resources/Story`): characters, NPCs, rooms, campaign,
/// scenes. To add content: edit or add JSON, run the tests / CaseLint (docs/story/).
public enum StoryLibrary {
    public static var directory: URL {
        Bundle.module.url(forResource: "Story", withExtension: nil)!
    }

    public static func load() throws -> StoryContent {
        try StoryContent.load(from: directory)
    }
}
