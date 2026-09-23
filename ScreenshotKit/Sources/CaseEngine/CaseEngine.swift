/// CaseEngine is the pure-Swift heart of SCREENSHOT.
///
/// Rules for this module:
/// - Foundation only. Never import SwiftUI, UIKit or SpriteKit here.
/// - No case content in code: every case is a JSON file (CaseLibrary). Adding a case never touches the engine.
/// - No tuning numbers in code: time costs, scoring… come from `GameRules` (JSON).
/// - Real time always comes from an injected `GameClock`, never from `Date()` directly.
public enum CaseEngine {
    public static let version = "0.2.0"
}
