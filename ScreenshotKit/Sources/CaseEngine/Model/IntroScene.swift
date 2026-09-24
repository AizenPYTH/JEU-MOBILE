/// The opening sequence of a case: a few shots (black screen with sounds, a place, a news report, the
/// phone where it was found, the unlock) that lead from the real world to the phone the player is
/// about to search.
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
        /// A place, filmed: a picture of `scene` with a camera move and an optional effect
        /// (a train arriving, a blackout, rain on a windscreen…). Lines are captions or announcements.
        case scene
        /// The phone lying where it was found (`surface`), its lock screen lighting up.
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
    /// More notifications (or an incoming call), in order.
    public var notifications: [IntroNotification]? = nil
    /// Scene shots: how the camera moves.
    public var camera: Camera? = nil
    /// Scene shots: what happens in the picture.
    public var effect: Effect? = nil
    /// Phone shots: what the phone lies on.
    public var surface: Surface? = nil

    public enum Camera: String, Codable, Sendable {
        case still, push, pull, panLeft, panRight, drift
    }

    public enum Effect: String, Codable, Sendable {
        /// Headlights sweep in, the picture shakes: a train pulls into the station.
        case trainArrival
        /// The lights go out, then red emergency lights.
        case blackout
        /// Rain streaks on a window or a windscreen.
        case rain
        /// Orange hazard lights blinking.
        case hazard
        /// Morning sun moving slowly through curtains.
        case sunlight
    }

    public enum Surface: String, Codable, Sendable {
        case wood, bench, glass, carSeat, sofa, marble
    }

    /// Every notification of the shot, in order.
    public var allNotifications: [IntroNotification] {
        ([notification].compactMap { $0 } + (notifications ?? [])).sorted { $0.at < $1.at }
    }
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
    /// An incoming call ringing (title = caller) instead of a banner.
    public var call: Bool? = nil
}
