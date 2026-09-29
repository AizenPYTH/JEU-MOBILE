#if os(iOS)
import Foundation

/// Game settings, stored on the device.
enum Preferences {
    static let vibrationsKey = "screenshot.vibrations"
    static let reduceMotionKey = "screenshot.reduceMotion"
    static let soundsKey = "screenshot.sounds"
    /// The Bureau's selected mode segment (Enquêtes · Alibi · Histoire), remembered (UX V3 §6-01).
    static let deskModeKey = "conclude.desk.mode"
    /// « Temps détendu » (final handoff §M): the timer is 1.5 × longer, without penalty.
    static let relaxedTimeKey = "conclude.relaxedTime"

    static var sounds: Bool {
        UserDefaults.standard.object(forKey: soundsKey) as? Bool ?? true
    }

    static var vibrations: Bool {
        UserDefaults.standard.object(forKey: vibrationsKey) as? Bool ?? true
    }

    static var relaxedTime: Bool {
        UserDefaults.standard.bool(forKey: relaxedTimeKey)
    }

    /// Timer factor applied when a case starts in « Temps détendu ».
    static let relaxedTimeFactor = 1.5
}
#endif
