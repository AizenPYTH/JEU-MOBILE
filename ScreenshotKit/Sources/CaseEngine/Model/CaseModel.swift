// The data model of a case. A case is pure data (one JSON file in CaseLibrary): the engine never
// contains case-specific code. Ids are unique across the whole case (checked by CaseValidator)
// so that any item can be referenced from evidence, hints, pins and live events.

public typealias ContactID = String
public typealias SuspectID = String

/// The phone owner in `from` / `contact` fields.
public let ownerContactID: ContactID = "me"

/// One investigation: "CASE #001 — LE DERNIER MESSAGE".
public struct CaseFile: Codable, Sendable, Identifiable {
    public var schemaVersion: Int
    public var id: String
    public var number: Int
    public var title: String
    /// One line under the title in the case list.
    public var tagline: String
    /// Briefing paragraphs shown before the timer starts.
    public var synopsis: [String]
    /// What the player must find out.
    public var objective: String
    /// 1 = simple (cases 1–5), 2 = intermediate, 3 = complex.
    public var difficulty: Int
    public var durationSeconds: Int
    /// Time shown on the phone when the investigation starts; it then runs in real time.
    public var phoneStartTime: Moment
    public var devices: [Device]
    public var suspects: [Suspect]
    public var evidence: [Evidence]
    public var hints: [Hint]
    public var solution: Solution
    /// Duration per challenge level ("investigator", "detective", "expert"), in seconds. Missing
    /// levels use the factors of `rules.json` (see `duration(for:rules:)`).
    public var challengeDurations: [String: Int]? = nil
    /// The opening sequence played before the phone (see `IntroScene`); nil = straight to the phone.
    public var introScene: IntroScene? = nil
}

// MARK: - Device (one seized phone)

public struct Device: Codable, Sendable, Identifiable {
    public var id: String
    /// "Téléphone d'Alex"
    public var label: String
    public var model: String
    /// Apps that need a code before they open (the code is hidden somewhere else in the phone).
    public var lockedApps: [AppLock]
    public var contacts: [Contact]
    public var conversations: [Conversation]
    public var calls: [Call]
    public var places: [Place]
    public var tracks: [LocationTrack]
    public var photos: [Photo]
    public var calendar: [CalendarEvent]
    public var notes: [Note]
    public var mails: [Mail]
    public var browser: [BrowserEntry]
    /// Things that happen *during* the investigation (notifications, incoming calls, deletions).
    public var liveEvents: [LiveEvent]
}

/// The apps of the phone. Order = home screen order.
public enum AppID: String, Codable, Sendable, CaseIterable, Hashable {
    case messages, phone, photos, location, calendar, notes, browser, mail, contacts, trash, settings, notifications
}

public struct AppLock: Codable, Sendable, Hashable {
    public var app: AppID
    public var code: String
    /// Shown on the lock screen, like a real password hint.
    public var hint: String?
}

public struct Contact: Codable, Sendable, Identifiable, Hashable {
    public var id: ContactID
    public var name: String
    public var phone: String
    public var relation: String?
    public var email: String?
    public var birthday: String?
    /// 0…1, used to generate a neutral avatar (initials on a tinted disc) — no illustrations.
    public var avatarHue: Double
    public var isOwner: Bool?

    public var initials: String {
        let words = name.split(separator: " ").prefix(2)
        return words.compactMap { $0.first }.map { String($0) }.joined().uppercased()
    }
}

// MARK: - Messages

public struct Conversation: Codable, Sendable, Identifiable {
    public var id: String
    /// Group name; nil for a one-to-one conversation (the contact's name is shown).
    public var title: String?
    /// Contacts other than the owner.
    public var participants: [ContactID]
    public var messages: [Message]
    /// A message typed but never sent.
    public var draft: Draft?

    public var isGroup: Bool { participants.count > 1 }
}

public struct Message: Codable, Sendable, Identifiable, Hashable {
    public var id: String
    /// Sender contact id, or `"me"` for the phone owner.
    public var from: ContactID
    public var at: Moment
    public var text: String?
    /// Attached photo (also visible in the Photos app).
    public var photo: String?
    /// Set when the message was deleted before the investigation: it only shows in the Trash
    /// ("Récemment supprimés") until the player recovers it.
    public var deletedAt: Moment?
    /// Unread when the phone was seized.
    public var unread: Bool?

    public var isFromOwner: Bool { from == ownerContactID }
}

public struct Draft: Codable, Sendable, Hashable {
    public var id: String
    public var text: String
    public var at: Moment
}

// MARK: - Calls

public struct Call: Codable, Sendable, Identifiable, Hashable {
    public enum Direction: String, Codable, Sendable {
        case incoming, outgoing, missed
    }

    public var id: String
    public var contact: ContactID
    public var direction: Direction
    public var at: Moment
    public var durationSeconds: Int
}

// MARK: - Location

public struct Place: Codable, Sendable, Identifiable, Hashable {
    public enum Kind: String, Codable, Sendable {
        case home, bar, work, parking, street, district, road, industrial, park, station, shop
    }

    public var id: String
    public var name: String
    public var kind: Kind
    /// Position on the stylised city map, 0…1 on both axes.
    public var x: Double
    public var y: Double
    /// Real-world position for the interactive map (both or neither).
    public var latitude: Double? = nil
    public var longitude: Double? = nil
    /// The place only appears on the map once one of these items has been seen (or a route through
    /// it opened). nil = shown from the start (home, work, the usual places).
    public var revealedBy: [ItemRef]? = nil
}

/// Position history of one person, as the owner's phone can see it
/// (the owner's own history, or a friend sharing their location).
public struct LocationTrack: Codable, Sendable, Identifiable {
    public var id: String
    public var contact: ContactID
    public var points: [TrackPoint]
    /// The person stopped sharing their location at this moment.
    public var sharingStoppedAt: Moment?
}

public struct TrackPoint: Codable, Sendable, Identifiable, Hashable {
    public var id: String
    public var at: Moment
    public var place: String
    public var note: String?
}

// MARK: - Photos

public struct Photo: Codable, Sendable, Identifiable, Hashable {
    public enum Source: String, Codable, Sendable {
        case camera, received, screenshot
    }

    public var id: String
    /// When the picture was *taken* (metadata). May differ from when it was received.
    public var takenAt: Moment
    public var source: Source
    public var from: ContactID?
    public var receivedAt: Moment?
    /// Place stored in the metadata, if any.
    public var place: String?
    public var device: String?
    /// Visual key used to render a generated, photographic-looking placeholder (no illustrations).
    public var scene: String
    /// What anyone sees at a glance.
    public var caption: String
    /// What a careful look reveals (shown after "Analyser").
    public var details: String
    /// How the picture was taken (selfie, night shot, document, screenshot, blurry, old…); drives
    /// how it is rendered. nil = an ordinary photo of its scene.
    public var style: Style? = nil
    /// Text legible in the picture itself (a document, a screenshot). Only what anyone can read at
    /// a glance: what needs a careful look belongs in `details`.
    public var lines: [String]? = nil

    public enum Style: String, Codable, Sendable {
        case standard, selfie, night, document, screenshot, blurry, old, quick
    }
}

// MARK: - Calendar, notes, mail, browser

public struct CalendarEvent: Codable, Sendable, Identifiable, Hashable {
    public var id: String
    public var start: Moment
    public var end: Moment?
    public var title: String
    public var location: String?
    public var notes: String?
    public var allDay: Bool?
}

public struct Note: Codable, Sendable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var body: String
    public var createdAt: Moment
    public var modifiedAt: Moment
}

public struct Mail: Codable, Sendable, Identifiable, Hashable {
    public enum Folder: String, Codable, Sendable {
        case inbox, sent
    }

    public var id: String
    public var folder: Folder
    public var fromName: String
    public var fromAddress: String
    public var to: String
    public var at: Moment
    public var subject: String
    public var body: String
    public var unread: Bool?
    /// File names of the attachments. The files themselves were never downloaded on the phone:
    /// only their names are visible (and searchable).
    public var attachments: [String]? = nil
}

public struct BrowserEntry: Codable, Sendable, Identifiable, Hashable {
    public enum Kind: String, Codable, Sendable {
        case search, visit
    }

    public var id: String
    public var at: Moment
    public var kind: Kind
    /// The query, or the page title.
    public var text: String
    public var url: String?
    /// What the page shows when opened.
    public var summary: String?
}

// MARK: - Live events

/// Something that happens while the player investigates: the phone keeps living.
public struct LiveEvent: Codable, Sendable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        /// A new message arrives in `conversation`.
        case message
        /// An incoming call rings, then shows as missed.
        case call
        /// A calendar reminder pops up.
        case reminder
        /// Someone deletes one of their messages (`deletesMessage`): it becomes "Message supprimé".
        case deletion
    }

    /// Banner priority: normal (4 s), important (6 s, outlined), urgent (inverted, stays until acted on).
    public enum Level: String, Codable, Sendable, Comparable {
        case normal, important, urgent

        private var rank: Int { self == .normal ? 0 : self == .important ? 1 : 2 }
        public static func < (a: Level, b: Level) -> Bool { a.rank < b.rank }
    }

    public var id: String
    public var level: Level?
    /// Seconds of investigation (real time + time costs) after which the event happens.
    public var afterSeconds: Int
    public var kind: Kind
    public var app: AppID
    public var title: String
    public var body: String
    public var conversation: String?
    public var message: Message?
    public var call: Call?
    public var deletesMessage: String?
    /// Item opened when the player taps the notification.
    public var opens: ItemRef?
}

// MARK: - Suspects, evidence, hints, solution

public struct Suspect: Codable, Sendable, Identifiable, Hashable {
    public var id: SuspectID
    public var contact: ContactID
    /// Link with the victim, e.g. "Meilleur ami d'Alex".
    public var role: String
    /// What they told the police. The player has to check it against the phone.
    public var statement: String
    /// Shown on the result screen when the player accuses this suspect.
    public var verdict: String
    public var age: Int?
    public var address: String?
    /// Why this person is innocent (the alibi card of a wrong accusation) — nil for the culprit.
    public var alibi: String?
    /// Evidence that proves the alibi.
    public var alibiEvidence: String?
    /// "Le piège": why this person looked guilty.
    public var trap: String?
}

public struct Evidence: Codable, Sendable, Identifiable, Hashable {
    public enum Importance: String, Codable, Sendable {
        /// Needed to prove the truth.
        case key
        /// Helps, e.g. clears another suspect.
        case supporting
        /// A false lead: true information that points the wrong way.
        case falseLead
    }

    public var id: String
    public var title: String
    /// What this piece of information really means (revealed on the result screen).
    public var meaning: String
    /// Items that reveal it. Found when *all* are seen, or *any* if `anyOf` is true.
    public var refs: [ItemRef]
    public var anyOf: Bool?
    public var importance: Importance
    /// Suspects this information is about.
    public var suspects: [SuspectID]
}

/// Hints come in tiers (clue, place, evidence). They cost score points, never the answer.
public struct Hint: Codable, Sendable, Identifiable, Hashable {
    public var id: String
    public var text: String
    /// Points removed from the final score (0 = free).
    public var scoreCost: Int
    /// Only available once the timer is at or below this many seconds.
    public var unlockAtRemainingSeconds: Int?
}

public struct Solution: Codable, Sendable, Hashable {
    public var culprit: SuspectID
    /// Short title of what happened.
    public var headline: String
    /// One sentence under the headline (narrative voice).
    public var summary: String
    /// The reconstruction, step by step (revealed every 700 ms on the result screen).
    public var reveal: [RevealStep]
    /// The full story, revealed paragraph by paragraph.
    public var story: [String]
}

public struct RevealStep: Codable, Sendable, Hashable {
    public var at: Moment
    public var text: String
    /// Evidence this step relies on: shown as found (●) or missed (○).
    public var evidence: String?
}
