import Foundation

// A story scene: a room, the people in it, and a list of beats played in order — someone enters,
// the camera cuts to Lacaze, a line of dialogue, Lacaze stands up and hands over a file, fade.
// Everything is data (Resources/Story/scenes/*.json); the engine (`StoryDirector`) plays it the
// same way every time, and the stage only draws what the director says.

/// A shot: one of the set's named cameras (« cam_lac_ms »), and what kind of shot it is — the kind
/// is the grammar of STORY_SCENES §2 (a scene opens WIDE, OBJECT FOCUS before the phone…).
public struct CameraShot: Codable, Sendable, Hashable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        /// 28–35 mm, people ≤ 1/3 of the frame: opens a scene, entrances and exits.
        case wide
        /// 50 mm, waist up: the default for dialogue.
        case medium
        /// 85 mm, shoulders up: an important line, a reaction, a silence.
        case closeUp
        /// 50 mm, the player's shoulder in the foreground.
        case overShoulder
        /// Two people in the frame.
        case twoShot
        /// Someone seen from the side.
        case profile
        /// 100 mm macro on an object (a file, the phone): always before going to the phone.
        case focusObject
    }

    public enum Move: String, Codable, Sendable {
        /// Still camera (the default).
        case cut
        /// A slow push-in (≤ 15 cm over the shot).
        case pushIn
        /// A slow lateral travelling (≤ 8 cm/s).
        case track
    }

    public var kind: Kind
    /// A camera of the room (`StoryLocation.cameras`).
    public var camera: String?
    /// Who the shot is on (the stage keeps the focus on their eyes).
    public var subject: String?
    public var other: String?
    /// OBJECT FOCUS: the prop in focus.
    public var prop: String?
    public var move: Move?

    public init(kind: Kind, camera: String? = nil, subject: String? = nil, other: String? = nil, prop: String? = nil, move: Move? = nil) {
        self.kind = kind
        self.camera = camera
        self.subject = subject
        self.other = other
        self.prop = prop
        self.move = move
    }
}

/// What makes a beat, a line or a choice happen — or not.
public struct StoryCondition: Codable, Sendable, Hashable {
    /// This flag is set.
    public var flag: String?
    /// This flag is not set.
    public var notFlag: String?
    /// The last case played in the story was solved (true) or not (false).
    public var lastCaseSolved: Bool?
    /// Trust of `npc` at least `atLeast`.
    public var npc: String?
    public var atLeast: Int?

    public init(flag: String? = nil, notFlag: String? = nil, lastCaseSolved: Bool? = nil, npc: String? = nil, atLeast: Int? = nil) {
        self.flag = flag
        self.notFlag = notFlag
        self.lastCaseSolved = lastCaseSolved
        self.npc = npc
        self.atLeast = atLeast
    }
}

/// A consequence: a relationship moves a little, something is remembered or unlocked.
public struct StoryEffect: Codable, Sendable, Hashable {
    public enum Kind: String, Codable, Sendable {
        /// `npc`'s trust changes by `amount`.
        case trust
        /// `npc`'s respect changes by `amount`.
        case respect
        /// Sets `flag` (a fact the story remembers).
        case flag
        /// Unlocks `id` (an office object « office_card », a chapter…). Ranks are never given by a
        /// scene: they follow the career rules (`StoryCampaign.career`).
        case unlock
    }

    public var kind: Kind
    public var npc: String?
    public var amount: Int?
    public var flag: String?
    public var id: String?

    public init(kind: Kind, npc: String? = nil, amount: Int? = nil, flag: String? = nil, id: String? = nil) {
        self.kind = kind
        self.npc = npc
        self.amount = amount
        self.flag = flag
        self.id = id
    }
}

/// One answer the player can give.
public struct DialogueChoice: Codable, Sendable, Hashable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        /// Changes nothing but the line that follows.
        case cosmetic
        /// Moves a relationship a little.
        case relational
        /// Sets a fact the story will remember.
        case narrative
    }

    public var id: String
    /// What the player answers (« Ne rien dire » for the silence).
    public var text: String
    public var kind: Kind?
    /// The silence: no player subtitle, the other person's close-up holds for 2 s.
    public var silent: Bool?
    /// A sentence the chapter result (h16, « VOS DÉCISIONS ») will show if this answer was chosen
    /// (« Vous avez demandé à Lacaze s'il vous aurait choisi. »).
    public var remember: String?
    /// The shot taken when this answer is given (the silence: the other person's close-up).
    public var shot: CameraShot?
    /// Silence only: how long it is held, seconds (2 by default).
    public var pause: Double?
    public var effects: [StoryEffect]?
    /// The node that answers (nil: the dialogue ends).
    public var next: String?
    public var condition: StoryCondition?

    public init(id: String, text: String, kind: Kind? = nil, silent: Bool? = nil, remember: String? = nil,
                shot: CameraShot? = nil, pause: Double? = nil,
                effects: [StoryEffect]? = nil, next: String? = nil, condition: StoryCondition? = nil) {
        self.id = id
        self.text = text
        self.kind = kind
        self.silent = silent
        self.remember = remember
        self.shot = shot
        self.pause = pause
        self.effects = effects
        self.next = next
        self.condition = condition
    }
}

/// One line: who speaks, what they say (with {player.lastName}…), how.
public struct DialogueNode: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    /// « player », an NPC id, or « narrator » (a caption, no speaker).
    public var speaker: String
    public var text: String
    /// neutral, serious, warm, tense, surprised, amused, tired (drives a small head/pose change).
    public var emotion: String?
    /// An animation the speaker plays with the line (« nod », « gesture »…).
    public var animation: String?
    /// The shot this line is seen in (the reaction's close-up…); nil keeps the current one.
    public var shot: CameraShot?
    /// Answers the player picks from (then `next` is ignored).
    public var choices: [DialogueChoice]?
    public var next: String?
    /// Consequences of reaching this line.
    public var effects: [StoryEffect]?
    /// Skipped (goes to `next`) when false.
    public var condition: StoryCondition?
    /// Optional recorded voice (a sound name); never required, text is always shown.
    public var voice: String?
}

/// One step of a scene.
public struct SceneBeat: Codable, Sendable, Hashable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        /// `actor` is at `anchor` (no animation: how the scene starts).
        case place
        /// `actor` comes in from `from` (a door anchor) and walks to `anchor`.
        case enter
        /// `actor` walks to `anchor`.
        case move
        /// `actor` walks to `anchor` and leaves the scene.
        case exit
        /// `actor` turns towards `target` (an actor or a prop).
        case face
        /// `actor` plays `animation`: stand, sit, nod, gesture, handover, typing, phone, shrug, idle.
        case animate
        /// The camera takes `shot`.
        case camera
        /// A conversation, from dialogue node `node` until a line without `next`. Waits for the player.
        case dialogue
        /// A pause of `seconds` (a silent shot: ambience only; `silence` lowers everything else).
        case wait
        /// A one-off sound (`sound`).
        case sound
        /// The looping ambience becomes `sound` (« none »: silence).
        case ambience
        /// `style` (cut, dissolve, fade) over `seconds`. Nothing else is allowed.
        case transition
        /// Consequences (`effects`).
        case effect
        /// The player's phone receives something (`title`, `text`, `app`): the player taps to go on
        /// (the investigation itself is the chapter's next step).
        case notification
        /// A title card (`text`, e.g. « CHAPITRE 1 — PREMIÈRE AFFECTATION »), `seconds` long.
        case title
        /// The hidden prop `target` appears on the set (a file put on the desk).
        case show
        /// The prop `target` leaves the set (taken away).
        case hide
    }

    public var kind: Kind
    public var actor: String?
    public var anchor: String?
    public var from: String?
    public var target: String?
    public var animation: String?
    public var shot: CameraShot?
    public var node: String?
    public var seconds: Double?
    public var sound: String?
    public var style: String?
    public var effects: [StoryEffect]?
    public var title: String?
    public var text: String?
    public var app: String?
    /// A narrative silence (wait beats): every track but the ambience goes down.
    public var silence: Bool?
    /// A resume point (STORY_SCENES §4).
    public var keyframe: Bool?
    /// Skipped when false.
    public var condition: StoryCondition?

    public init(kind: Kind) { self.kind = kind }

    /// The allowed transition styles.
    public static let transitionStyles: Set<String> = ["cut", "dissolve", "fade"]
}

/// A scene of the story.
public struct StoryScene: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var title: String?
    /// The room (a `StoryLocation` id).
    public var location: String
    /// « BEN · BUREAU 312 · 21:04 »: shown top left on the opening wide shot, then fades.
    public var place: String?
    /// « player » and NPC ids (3 people on screen at most).
    public var participants: [String]
    public var beats: [SceneBeat]
    public var dialogue: [DialogueNode]

    public func node(_ id: String) -> DialogueNode? { dialogue.first { $0.id == id } }
}
