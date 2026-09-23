import Foundation
import CaseEngine

/// The cases shipped with the game (JSON in `Resources/Cases`) and the rules (`Resources/Rules`).
/// To add a case: drop a new `case_XXX.json` in Resources/Cases and run the tests / CaseLint.
public enum CaseLibrary {
    public static var casesDirectory: URL {
        Bundle.module.url(forResource: "Cases", withExtension: nil)!
    }

    public static var rulesURL: URL {
        Bundle.module.url(forResource: "Rules", withExtension: nil)!.appendingPathComponent("rules.json")
    }

    public static func loadCases() throws -> [CaseFile] {
        try CaseLoader.loadCases(in: casesDirectory)
    }

    public static func loadRules() throws -> GameRules {
        guard let data = try? Data(contentsOf: rulesURL) else { throw CaseLoadError.missingFile("rules.json") }
        return try CaseLoader.loadRules(data)
    }
}
