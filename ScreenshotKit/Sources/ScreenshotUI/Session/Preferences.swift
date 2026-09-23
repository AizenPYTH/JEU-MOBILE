#if os(iOS)
import Foundation

/// Game settings (screen 07), stored on the device.
enum Preferences {
    static let vibrationsKey = "screenshot.vibrations"
    static let reduceMotionKey = "screenshot.reduceMotion"

    static var vibrations: Bool {
        UserDefaults.standard.object(forKey: vibrationsKey) as? Bool ?? true
    }
}
#endif
