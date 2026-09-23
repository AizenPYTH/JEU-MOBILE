import SwiftUI
import BistroUI

/// Thin app shell: all game code lives in the BistroKit package.
@main
struct BistroApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
