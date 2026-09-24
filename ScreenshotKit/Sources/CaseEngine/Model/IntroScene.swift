/// The opening sequence of a case: a few shots (black screen with sounds, a news report, the phone on
/// a table, the unlock) that lead from the real world to the phone the player is about to search.
/// Pure data: every case can have its own, the player (`CinematicView`) is generic.
public struct IntroScene: Codable, Sendable, Hashable {
    public var shots: [IntroShot]

    public var totalSeconds: Double { shots.reduce(0) { $0 + $1.seconds } }
}

public struct IntroShot: Codable, Sendable, Hashable {
    public enum Kind: String, Codable, Sendable {
        /// Black screen: sounds, a line of text.
        case title
        /// A live news report in front of a place (the camera stays on the place).
        case broadcast
        /// The seized phone lying on a table, its lock screen lighting up.
        case phoneOnTable
        /// The phone is picked up and unlocked: the home screen appears, then the game.
        case unlock
    }

    public var kind: Kind
    public var seconds: Double
    /// Looping ambience sounds for the whole shot ("street", "sirens", "crowd"…).
    public var ambience: [String]? = nil
    /// One-off sounds at a given offset ("vibrate", "notification", "unlock"…).
    public var cues: [IntroCue]? = nil
    /// Text on screen (and spoken, if `voiced`).
    public var lines: [IntroLine]? = nil
    /// Broadcast: channel name, place, headline, scrolling ticker.
    public var channel: String? = nil
    public var location: String? = nil
    public var headline: String? = nil
    public var ticker: String? = nil
    /// Background picture (a photo scene key, e.g. "parking_night").
    public var scene: String? = nil
    /// A label in the shot (e.g. the evidence bag tag next to the phone).
    public var label: String? = nil
    /// A notification arriving on the lock screen.
    public var notification: IntroNotification? = nil
}

public struct IntroLine: Codable, Sendable, Hashable {
    public var text: String
    /// Seconds from the start of the shot.
    public var at: Double
    public var speaker: String? = nil
    /// Read aloud by the system voice.
    public var voiced: Bool? = nil
}

public struct IntroCue: Codable, Sendable, Hashable {
    public var sound: String
    public var at: Double
}

public struct IntroNotification: Codable, Sendable, Hashable {
    public var app: AppID
    public var title: String
    public var body: String
    public var at: Double
}
