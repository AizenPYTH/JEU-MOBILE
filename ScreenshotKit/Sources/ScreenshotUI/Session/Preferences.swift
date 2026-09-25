#if os(iOS)
import Foundation

/// Game settings (screen 07), stored on the device.
enum Preferences {
    static let vibrationsKey = "screenshot.vibrations"
    static let reduceMotionKey = "screenshot.reduceMotion"
    static let soundsKey = "screenshot.sounds"
    /// Accessibility: handwritten annotations in a legible serif instead of Caveat.
    static let legibleHandwritingKey = "trace.legibleHandwriting"

    static let onboardingDoneKey = "screenshot.onboardingDone"

    /// The three-step onboarding is shown on the first launch only.
    static var onboardingDone: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingDoneKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingDoneKey) }
    }

    static var sounds: Bool {
        UserDefaults.standard.object(forKey: soundsKey) as? Bool ?? true
    }

    static var vibrations: Bool {
        UserDefaults.standard.object(forKey: vibrationsKey) as? Bool ?? true
    }
}
#endif
