import SwiftUI
import ScreenshotUI

/// Thin app shell: the whole game lives in the ScreenshotKit package.
@main
struct ScreenshotApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
