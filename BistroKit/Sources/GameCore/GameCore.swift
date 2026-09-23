/// GameCore is the pure-Swift heart of Bistro.
///
/// Rules for this module:
/// - Foundation only. Never import SwiftUI, UIKit or SpriteKit here.
/// - No hard-coded balance numbers: every tunable value comes from `GameConfig` (JSON).
/// - No hard-coded content: ingredients, recipes, regulars… come from `GameContent` (JSON).
/// - Time always comes from an injected `GameClock`, never from `Date()` directly.
public enum GameCore {
    public static let version = "0.1.0"
}
