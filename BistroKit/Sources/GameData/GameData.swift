import Foundation
import GameCore

/// Gives access to the JSON files bundled with the game.
///
/// To rebalance the game, edit the files in `Resources/Config`.
/// To add content, edit the files in `Resources/Content` (then run the tests: they validate everything).
public enum GameData {
    public static var contentDirectory: URL {
        Bundle.module.url(forResource: "Content", withExtension: nil)!
    }

    public static var configDirectory: URL {
        Bundle.module.url(forResource: "Config", withExtension: nil)!
    }

    public static func loadContent() throws -> GameContent {
        try ContentLoader.load(from: contentDirectory)
    }

    public static func loadConfig() throws -> GameConfig {
        try ConfigLoader.load(from: configDirectory)
    }
}
