import Foundation

// The campaign: chapters, each a short sequence of steps — scenes at the BEN, an investigation on
// the phone, a reward — played in order. A chapter ends with its last step, unlocks the next one,
// and usually moves the career on. Resources/Story/campaign.json.

/// Ranks of the BEN (the same titles as the main mode; with a story investigator, one career for
/// the whole game).
public enum StoryRank: String, Codable, Sendable, CaseIterable, Comparable {
    case enqueteur, inspecteur, senior, experimente

    public static func < (a: StoryRank, b: StoryRank) -> Bool {
        allCases.firstIndex(of: a)! < allCases.firstIndex(of: b)!
    }
}

/// An object added to the player's office (h18): never money, a percentage or a boost.
public struct RewardItem: Codable, Sendable, Hashable, Identifiable {
    /// The unlock it gives (a prop of the player's office `requires` it).
    public var id: String
    public var name: String
    /// « Remise par le Cdt. Lacaze, octobre 2026 ».
    public var provenance: String?
}

/// What a chapter gives at its result: objects for the office, unlocks, facts.
public struct StoryReward: Codable, Sendable, Hashable {
    public var items: [RewardItem]?
    public var unlocks: [String]?
    public var flags: [String]?

    public init(items: [RewardItem]? = nil, unlocks: [String]? = nil, flags: [String]? = nil) {
        self.items = items
        self.unlocks = unlocks
        self.flags = flags
    }

    /// Everything this reward unlocks (its objects included).
    public var allUnlocks: [String] { (items ?? []).map(\.id) + (unlocks ?? []) }
}

/// A rank of the career and what it takes: `cases` cases solved (all modes) AND chapter
/// `chapter` finished — both are needed (CHARACTER_CUSTOMIZATION §6).
public struct CareerTier: Codable, Sendable, Hashable {
    public var rank: StoryRank
    public var cases: Int
    /// A chapter number (nil: no chapter needed).
    public var chapter: Int?
}

/// One step of a chapter.
public struct ChapterStep: Codable, Sendable, Hashable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        /// Plays `scene`.
        case scene
        /// Plays the investigation `caseID` on the phone (an ENQUÊTES or ALIBI case; its result is
        /// remembered for the next steps: `StoryCondition.lastCaseSolved`).
        case investigation
        /// The chapter's result (h16), the career (h17) and the reward (h18): the chapter counts as
        /// finished from here, for the career.
        case result
        /// Opens the player's office (h09), then goes on.
        case office
    }

    public var id: String
    public var kind: Kind
    /// Shown in the chapter's list of steps (h10).
    public var title: String?
    /// A step with a surprise: its title stays « ··· » until it is reached.
    public var surprise: Bool?
    public var scene: String?
    public var caseID: String?
    public var reward: StoryReward?
    /// Skipped when false (e.g. a scene only after a failed case).
    public var condition: StoryCondition?
}

public struct StoryChapter: Codable, Sendable, Hashable, Identifiable {
    public enum Status: String, Codable, Sendable {
        /// Written and playable.
        case playable
        /// Announced (title, synopsis) but not written yet: shown as « à venir ».
        case planned
    }

    public var id: String
    public var number: Int
    public var title: String
    /// Two lines, shown on the chapter's folder (h10).
    public var synopsis: String
    public var status: Status
    public var steps: [ChapterStep]
    /// Result (h16): two sentences when every case was solved, and the variant when one failed.
    public var summary: String?
    public var summaryUnsolved: String?
    /// Lacaze's note on the career sheet (h17).
    public var note: String?
}

public struct StoryCampaign: Codable, Sendable {
    public var chapters: [StoryChapter]
    /// The ranks and their conditions, in order (the first one is the starting rank).
    public var career: [CareerTier]
    /// Game time per chapter, in months (seniority on the profile).
    public var monthsPerChapter: Int?

    public init(chapters: [StoryChapter], career: [CareerTier] = [], monthsPerChapter: Int? = nil) {
        self.chapters = chapters
        self.career = career
        self.monthsPerChapter = monthsPerChapter
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        chapters = try c.decode([StoryChapter].self, forKey: .chapters)
        career = try c.decodeIfPresent([CareerTier].self, forKey: .career) ?? []
        monthsPerChapter = try c.decodeIfPresent(Int.self, forKey: .monthsPerChapter)
    }

    /// The rank earned with `solved` cases and these chapters finished.
    public func rank(solved: Int, chapters finished: Set<Int>) -> StoryRank {
        var rank = StoryRank.enqueteur
        for tier in career where solved >= tier.cases && (tier.chapter.map { finished.contains($0) } ?? true) {
            rank = max(rank, tier.rank)
        }
        return rank
    }

    /// The tier after `rank` (nil at the top).
    public func tier(after rank: StoryRank) -> CareerTier? {
        career.filter { $0.rank > rank }.min { $0.rank < $1.rank }
    }

    public func tier(_ rank: StoryRank) -> CareerTier? { career.first { $0.rank == rank } }

    public func chapter(_ id: String) -> StoryChapter? { chapters.first { $0.id == id } }

    /// The chapter after `id` (nil at the end).
    public func chapter(after id: String) -> StoryChapter? {
        guard let i = chapters.firstIndex(where: { $0.id == id }), i + 1 < chapters.count else { return nil }
        return chapters[i + 1]
    }
}

/// Everything the story is made of, loaded once.
public struct StoryContent: Sendable {
    public var catalog: CharacterCatalog
    public var npcs: [StoryNPC]
    public var locations: [StoryLocation]
    public var campaign: StoryCampaign
    public var scenes: [StoryScene]

    public init(catalog: CharacterCatalog, npcs: [StoryNPC], locations: [StoryLocation], campaign: StoryCampaign, scenes: [StoryScene]) {
        self.catalog = catalog
        self.npcs = npcs
        self.locations = locations
        self.campaign = campaign
        self.scenes = scenes
    }

    public func npc(_ id: String) -> StoryNPC? { npcs.first { $0.id == id } }
    public func location(_ id: String) -> StoryLocation? { locations.first { $0.id == id } }
    public func scene(_ id: String) -> StoryScene? { scenes.first { $0.id == id } }

    /// Reads a story folder: characters.json, npcs.json, locations.json, campaign.json, scenes/*.json.
    public static func load(from directory: URL) throws -> StoryContent {
        let decoder = JSONDecoder()
        func read<T: Decodable>(_ name: String, as: T.Type) throws -> T {
            let url = directory.appendingPathComponent(name)
            do {
                return try decoder.decode(T.self, from: Data(contentsOf: url))
            } catch {
                throw StoryLoadError(file: name, reason: String(describing: error))
            }
        }
        struct NPCFile: Decodable { var npcs: [StoryNPC] }
        struct LocationFile: Decodable { var locations: [StoryLocation] }
        let sceneDir = directory.appendingPathComponent("scenes")
        let sceneFiles = (try? FileManager.default.contentsOfDirectory(at: sceneDir, includingPropertiesForKeys: nil)) ?? []
        var scenes: [StoryScene] = []
        for url in sceneFiles.filter({ $0.pathExtension == "json" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            struct SceneFile: Decodable { var scenes: [StoryScene] }
            do {
                scenes += try decoder.decode(SceneFile.self, from: Data(contentsOf: url)).scenes
            } catch {
                throw StoryLoadError(file: "scenes/" + url.lastPathComponent, reason: String(describing: error))
            }
        }
        return StoryContent(catalog: try read("characters.json", as: CharacterCatalog.self),
                            npcs: try read("npcs.json", as: NPCFile.self).npcs,
                            locations: try read("locations.json", as: LocationFile.self).locations,
                            campaign: try read("campaign.json", as: StoryCampaign.self),
                            scenes: scenes)
    }
}

public struct StoryLoadError: Error, CustomStringConvertible, Sendable {
    public var file: String
    public var reason: String
    public var description: String { "\(file): \(reason)" }
}
