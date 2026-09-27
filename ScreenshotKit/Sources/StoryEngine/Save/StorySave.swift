import Foundation

// The story's save: who the player is, where they are (chapter, step, scene, beat, line), what
// they earned and how the people of the BEN see them. Versioned: `StorySaveCoder` reads every
// earlier version and migrates it — an old save is never lost. Separate from the main mode's
// attempts and from the ALIBI checks: playing one never touches the others.

/// Exactly where the player is. Replaying the scene's beats up to `beatIndex` rebuilds the stage
/// (the director is deterministic), so only indices are saved.
public struct StoryPosition: Codable, Sendable, Hashable {
    public var chapterID: String
    /// The step being played (== steps.count: the chapter is finished).
    public var stepIndex: Int
    /// The scene being played (nil between steps).
    public var sceneID: String?
    /// Beats already applied.
    public var beatIndex: Int
    /// The line on screen, waiting for the player.
    public var nodeID: String?
    /// After a silent answer: the line that follows the held silence.
    public var afterPause: String?
    /// The investigation being played on the phone (its own save lives with the phone's).
    public var awaitingCase: String?
    /// « result » (h16–h18) or « office » (h09) is on screen.
    public var showing: String?

    public init(chapterID: String, stepIndex: Int = 0, sceneID: String? = nil, beatIndex: Int = 0,
                nodeID: String? = nil, awaitingCase: String? = nil, showing: String? = nil) {
        self.chapterID = chapterID
        self.stepIndex = stepIndex
        self.sceneID = sceneID
        self.beatIndex = beatIndex
        self.nodeID = nodeID
        self.awaitingCase = awaitingCase
        self.showing = showing
    }
}

/// How a colleague sees the player. Never shown as a number: dialogues read it.
public struct StoryRelationship: Codable, Sendable, Hashable {
    public var trust: Int
    public var respect: Int

    public init(trust: Int = 0, respect: Int = 0) {
        self.trust = trust
        self.respect = respect
    }

    /// tense, reserved, cordial, trusted.
    public var state: String {
        switch trust {
        case ..<(-1): "tense"
        case -1...2: "reserved"
        case 3...5: "cordial"
        default: "trusted"
        }
    }
}

/// An investigation played in the story.
public struct StoryCaseRecord: Codable, Sendable, Hashable {
    public var caseID: String
    public var solved: Bool
    public var score: Int
    public var found: Int
    public var total: Int
    public var attempts: Int
    /// Seconds of investigation (the chapter's total time, h16).
    public var seconds: Int?
    /// An ALIBI check (counted as handled, never as solved).
    public var alibi: Bool?
}

/// A line of the profile's history (h07): « Première affectation », « Promotion : Inspecteur »…
public struct StoryHistoryEntry: Codable, Sendable, Hashable {
    /// « 2026-10-09 » (given by the app: the engine never reads the clock).
    public var date: String
    public var text: String

    public init(date: String, text: String) {
        self.date = date
        self.text = text
    }
}

/// A chapter replayed from the settings (h19): choices shown, nothing counts; at the end the
/// player is back where they were.
public struct StoryReplay: Codable, Sendable, Hashable {
    public var chapterID: String
    public var returnPosition: StoryPosition
    public var returnLastCaseSolved: Bool?
}

/// A rank just reached, waiting to be shown (h17 then « Avancement de service »).
public struct StoryPromotion: Codable, Sendable, Hashable {
    public var from: StoryRank
    public var to: StoryRank
}

/// The few numbers of the career (no RPG sheet).
public struct StoryStats: Codable, Sendable, Hashable {
    public var casesCompleted = 0
    public var casesSolved = 0
    public var mistakes = 0
    public var cluesFound = 0
    public var chaptersCompleted = 0

    public init() {}
}

public struct StorySave: Codable, Sendable, Hashable {
    public static let currentVersion = 2

    public var version: Int
    public var player: StoryPlayer
    public var position: StoryPosition
    public var rank: StoryRank
    /// Outfits, office items, chapters… (« outfit_inspector », « office_plaque », « chapter_02 »).
    public var unlocks: Set<String>
    /// Facts the story remembers (choices, outcomes).
    public var flags: Set<String>
    public var relationships: [String: StoryRelationship]
    public var cases: [String: StoryCaseRecord]
    public var completedChapters: [String]
    public var lastCaseSolved: Bool?
    public var stats: StoryStats
    /// Scenes played to the end (« PASSER » is offered on those only).
    public var seenScenes: Set<String>
    /// The answer given at each question (« sceneID#nodeID » → choice id).
    public var choices: [String: String]
    /// Sentences of the remembered answers, per chapter (h16 « VOS DÉCISIONS »).
    public var decisions: [String: [String]]
    public var history: [StoryHistoryEntry]
    /// Office points already opened (a new one has a red ring until then).
    public var seenHotspots: Set<String>
    public var replay: StoryReplay?
    public var promotion: StoryPromotion?
    /// « 2026-09-27 »: the day the investigator was created.
    public var createdAt: String?

    public init(player: StoryPlayer, firstChapter: String, createdAt: String? = nil) {
        self.version = Self.currentVersion
        self.player = player
        self.position = StoryPosition(chapterID: firstChapter)
        self.rank = .enqueteur
        self.unlocks = [firstChapter]
        self.flags = []
        self.relationships = [:]
        self.cases = [:]
        self.completedChapters = []
        self.lastCaseSolved = nil
        self.stats = StoryStats()
        self.seenScenes = []
        self.choices = [:]
        self.decisions = [:]
        self.history = []
        self.seenHotspots = []
        self.replay = nil
        self.promotion = nil
        self.createdAt = createdAt
    }

    /// The chapter numbers finished (for the career).
    public func finishedChapterNumbers(in campaign: StoryCampaign) -> Set<Int> {
        Set(completedChapters.compactMap { id in campaign.chapter(id)?.number })
    }

    public func relationship(_ npc: String) -> StoryRelationship { relationships[npc] ?? StoryRelationship() }
}

public enum StorySaveError: Error, Equatable, Sendable {
    case unreadable
    /// A save written by a later version of the game.
    case tooRecent(Int)
}

/// Reads and writes saves; migrates every known earlier version.
public enum StorySaveCoder {
    public static func encode(_ save: StorySave) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(save)
    }

    public static func decode(_ data: Data) throws -> StorySave {
        guard var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { throw StorySaveError.unreadable }
        let version = object["version"] as? Int ?? 0
        if version > StorySave.currentVersion { throw StorySaveError.tooRecent(version) }
        if version < 1 { object = migrate0to1(object) }
        if version < 2 { object = migrate1to2(object) }
        guard let migrated = try? JSONSerialization.data(withJSONObject: object),
              let save = try? JSONDecoder().decode(StorySave.self, from: migrated) else { throw StorySaveError.unreadable }
        return save
    }

    /// Version 0 is the draft layout of the first prototypes: `chapter`, `scene`, `beat` at the top
    /// level, `progress.rank`, `progress.unlocked`, no relationships.
    static func migrate0to1(_ old: [String: Any]) -> [String: Any] {
        var new = old
        new["version"] = 1
        if new["position"] == nil {
            new["position"] = ["chapterID": old["chapter"] as? String ?? "chapter_01",
                               "stepIndex": old["step"] as? Int ?? 0,
                               "sceneID": old["scene"] as Any,
                               "beatIndex": old["beat"] as? Int ?? 0].compactMapValues { $0 is NSNull ? nil : $0 }
        }
        let progress = old["progress"] as? [String: Any] ?? [:]
        new["rank"] = new["rank"] ?? progress["rank"] ?? "enqueteur"
        new["unlocks"] = new["unlocks"] ?? progress["unlocked"] ?? []
        new["flags"] = new["flags"] ?? progress["flags"] ?? []
        new["relationships"] = new["relationships"] ?? [String: Any]()
        new["cases"] = new["cases"] ?? [String: Any]()
        new["completedChapters"] = new["completedChapters"] ?? progress["completedChapters"] ?? []
        new["stats"] = new["stats"] ?? ["casesCompleted": 0, "casesSolved": 0, "mistakes": 0, "cluesFound": 0, "chaptersCompleted": 0]
        for key in ["chapter", "step", "scene", "beat", "progress"] { new.removeValue(forKey: key) }
        return new
    }

    /// Version 2 (the story handoff): agreement and face on the player, seen scenes, remembered
    /// answers, history, office points, replay.
    static func migrate1to2(_ old: [String: Any]) -> [String: Any] {
        var new = old
        new["version"] = 2
        if var player = old["player"] as? [String: Any] {
            var appearance = player["appearance"] as? [String: Any] ?? [:]
            let presentation = appearance["presentation"] as? String ?? "presentation_f"
            appearance["face"] = appearance["face"] ?? "face_01"
            appearance.removeValue(forKey: "accessory")
            player["appearance"] = appearance
            player["agreement"] = player["agreement"] ?? Agreement(presentation: presentation).rawValue
            new["player"] = player
        }
        new["seenScenes"] = new["seenScenes"] ?? [String]()
        new["choices"] = new["choices"] ?? [String: String]()
        new["decisions"] = new["decisions"] ?? [String: [String]]()
        new["history"] = new["history"] ?? [Any]()
        new["seenHotspots"] = new["seenHotspots"] ?? [String]()
        if var position = new["position"] as? [String: Any], position["showing"] as? String == "reward" {
            position["showing"] = "result"
            new["position"] = position
        }
        return new
    }
}
