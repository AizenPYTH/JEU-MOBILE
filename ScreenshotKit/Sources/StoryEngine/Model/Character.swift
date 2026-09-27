import Foundation

// The player's investigator and the people of the story. Appearance is chosen among stable,
// data-defined variants (`CharacterCatalog`, Resources/Story/characters.json): adding a haircut or
// an outfit is adding a line of data, never code.

/// One part of the look that can vary.
public enum AppearanceSlot: String, Codable, Sendable, CaseIterable {
    /// The base (FÉMININE / MASCULINE): the only structural choice (skeleton, proportions).
    case presentation
    case skinTone
    /// Face preset (oval, long, square, round, angular, heart).
    case face
    case hairStyle, hairColor
    /// Facial hair (masculine base only; « beard_none » otherwise).
    case beard
    case eyeColor
    /// An outfit and its colour variant (« outfit_01a », « outfit_01b »…).
    case outfit
}

/// How a character looks, as variant ids (« hair_02 », « outfit_01 »…). Stable ids: saves keep
/// them, a later version may add variants but never renames one.
public struct CharacterAppearance: Codable, Sendable, Hashable {
    public var presentation: String
    public var skinTone: String
    public var face: String
    public var hairStyle: String
    public var hairColor: String
    public var beard: String
    public var eyeColor: String
    public var outfit: String

    public init(presentation: String, skinTone: String, face: String, hairStyle: String, hairColor: String, beard: String,
                eyeColor: String, outfit: String) {
        self.presentation = presentation
        self.skinTone = skinTone
        self.face = face
        self.hairStyle = hairStyle
        self.hairColor = hairColor
        self.beard = beard
        self.eyeColor = eyeColor
        self.outfit = outfit
    }

    public subscript(slot: AppearanceSlot) -> String {
        get {
            switch slot {
            case .presentation: presentation
            case .skinTone: skinTone
            case .face: face
            case .hairStyle: hairStyle
            case .hairColor: hairColor
            case .beard: beard
            case .eyeColor: eyeColor
            case .outfit: outfit
            }
        }
        set {
            switch slot {
            case .presentation: presentation = newValue
            case .skinTone: skinTone = newValue
            case .face: face = newValue
            case .hairStyle: hairStyle = newValue
            case .hairColor: hairColor = newValue
            case .beard: beard = newValue
            case .eyeColor: eyeColor = newValue
            case .outfit: outfit = newValue
            }
        }
    }
}

/// One choice in the character creator: « Cheveux courts », « Veste de terrain »…
public struct CharacterVariant: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var slot: AppearanceSlot
    /// Name shown in the creator (French; `labelEn` for English).
    public var label: String
    public var labelEn: String?
    /// Main colour, « #RRGGBB » (skin, hair, eyes, outfit…), used by the 3D stage and the swatches.
    public var color: String?
    /// Second colour (an outfit's shirt, a scarf…).
    public var accent: String?
    /// Shape used by the 3D stage for this variant (« short », « bun », « oval »…).
    public var shape: String?
    /// Outfits: the outfit this colour variant belongs to (« outfit_01 »), shown as one card with
    /// its variants in the creator.
    public var group: String?
    /// Only offered to these presentations (nil = all).
    public var presentations: [String]?
    /// Locked until this story unlock is obtained; nil = always available.
    public var unlock: String?
    /// Worn by the people of the BEN only (Lacaze's shirt and tie…): never offered to the player.
    public var npcOnly: Bool?
}

/// Every variant the game knows, and the look of a new investigator.
public struct CharacterCatalog: Codable, Sendable {
    public var variants: [CharacterVariant]
    public var defaultAppearance: CharacterAppearance
    /// The starting models of the creator (Élise Morel, Vincent Delmas): a name and a look,
    /// all editable.
    public var templates: [CharacterTemplate]

    public init(variants: [CharacterVariant], defaultAppearance: CharacterAppearance, templates: [CharacterTemplate] = []) {
        self.variants = variants
        self.defaultAppearance = defaultAppearance
        self.templates = templates
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        variants = try c.decode([CharacterVariant].self, forKey: .variants)
        defaultAppearance = try c.decode(CharacterAppearance.self, forKey: .defaultAppearance)
        templates = try c.decodeIfPresent([CharacterTemplate].self, forKey: .templates) ?? []
    }

    public func template(_ id: String) -> CharacterTemplate? { templates.first { $0.id == id } }

    public func variant(_ id: String) -> CharacterVariant? { variants.first { $0.id == id } }

    /// The variants of a slot the player may pick now.
    public func options(for slot: AppearanceSlot, presentation: String, unlocked: Set<String>) -> [CharacterVariant] {
        variants.filter { v in
            v.slot == slot
                && v.npcOnly != true
                && (v.presentations == nil || v.presentations!.contains(presentation))
                && (v.unlock == nil || unlocked.contains(v.unlock!))
        }
    }

    /// An appearance whose every part exists, fits the presentation and is unlocked.
    public func isValid(_ appearance: CharacterAppearance, unlocked: Set<String>) -> Bool {
        AppearanceSlot.allCases.allSatisfy { slot in
            let id = appearance[slot]
            if slot == .presentation { return variant(id)?.slot == .presentation }
            return options(for: slot, presentation: appearance.presentation, unlocked: unlocked).contains { $0.id == id }
        }
    }

    /// The same appearance, with every part that no longer fits (a new presentation, a locked
    /// outfit) replaced by the first option that does.
    public func fitted(_ appearance: CharacterAppearance, unlocked: Set<String>) -> CharacterAppearance {
        var result = appearance
        for slot in AppearanceSlot.allCases where slot != .presentation {
            let options = options(for: slot, presentation: result.presentation, unlocked: unlocked)
            if !options.contains(where: { $0.id == result[slot] }), let first = options.first {
                result[slot] = first.id
            }
        }
        return result
    }
}

/// A starting model of the creator (the two investigators of « Qui enquête ? »).
public struct CharacterTemplate: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var firstName: String
    public var lastName: String
    public var agreement: Agreement
    public var appearance: CharacterAppearance
}

/// Grammatical agreement of the player's titles: Enquêtrice / Enquêteur / Agent, affectée / affecté.
public enum Agreement: String, Codable, Sendable, CaseIterable {
    case feminine = "f", masculine = "m", neutral = "n"

    /// The agreement that goes with a base (the player may change it afterwards).
    public init(presentation: String) {
        switch presentation {
        case "presentation_f": self = .feminine
        case "presentation_m": self = .masculine
        default: self = .neutral
        }
    }
}

/// The investigator the player created.
public struct StoryPlayer: Codable, Sendable, Hashable {
    public var firstName: String
    public var lastName: String
    public var appearance: CharacterAppearance
    public var agreement: Agreement
    /// « BEN-0xxxx », generated once at creation and never changed.
    public var serviceNumber: String

    public init(firstName: String, lastName: String, appearance: CharacterAppearance, agreement: Agreement? = nil,
                serviceNumber: String? = nil) {
        self.firstName = Self.normalized(firstName)
        self.lastName = Self.normalized(lastName)
        self.appearance = appearance
        self.agreement = agreement ?? Agreement(presentation: appearance.presentation)
        self.serviceNumber = serviceNumber ?? Self.serviceNumber(for: firstName + " " + lastName)
    }

    /// A stable number from a seed (the app passes the name and the creation time, so two
    /// investigators of the same name on one device still get different numbers).
    public static func serviceNumber(for seed: String) -> String {
        var hash: UInt32 = 2_166_136_261
        for byte in seed.lowercased().utf8 { hash = (hash ^ UInt32(byte)) &* 16_777_619 }
        return "BEN-0" + String(format: "%04d", Int(hash % 9000) + 1000)
    }

    /// Trimmed, single spaces, capital initial on each word (« jean-marc » → « Jean-Marc »).
    public static func normalized(_ name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace).map(String.init)
        return words.map { word in
            var out = ""
            var upper = true
            for ch in word {
                out += upper ? ch.uppercased() : String(ch)
                upper = ch == "-" || ch == "'" || ch == "’"
            }
            return out
        }.joined(separator: " ")
    }

    /// 2 to 20 characters: letters (accents too), space, apostrophe, hyphen.
    public static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard (2...20).contains(trimmed.count), trimmed.contains(where: \.isLetter) else { return false }
        return trimmed.allSatisfy { $0.isLetter || $0 == "-" || $0 == "'" || $0 == "’" || $0 == " " }
    }

    /// Why a name cannot go on an official file (nil: it can). `reserved`: full names of the
    /// story's characters (« Bernard Lacaze »…), which the player cannot take.
    public static func nameProblem(firstName: String, lastName: String, reserved: [String]) -> NameProblem? {
        guard isValidName(firstName), isValidName(lastName) else { return .format }
        let words = (firstName + " " + lastName).lowercased().folding(options: .diacriticInsensitive, locale: nil)
            .split { !$0.isLetter }.map(String.init)
        if words.contains(where: { blockedWords.contains($0) }) { return .offensive }
        let full = normalized(firstName + " " + lastName).lowercased()
        if reserved.contains(where: { $0.lowercased() == full }) { return .reserved }
        return nil
    }

    public enum NameProblem: Sendable, Equatable { case format, offensive, reserved }

    /// A short local list (FR + EN). Whole words only: « Cassandre » is never refused for « ass ».
    static let blockedWords: Set<String> = [
        "merde", "putain", "pute", "connard", "connasse", "salope", "encule", "enculee", "batard", "bite", "couille",
        "couilles", "nique", "niquer", "pd", "tapette", "negre", "bougnoule", "youpin", "nazi", "hitler", "fdp", "ntm",
        "fuck", "fucker", "shit", "bitch", "cunt", "dick", "cock", "pussy", "whore", "slut", "bastard", "asshole", "nigger",
        "nigga", "fag", "faggot", "retard", "rape", "rapist",
    ]
}

/// A recurring character of the story (Commandant Lacaze, the colleagues…).
public struct StoryNPC: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var firstName: String
    public var lastName: String
    /// « Commandant », « Enquêtrice »…
    public var title: String
    public var role: String
    public var appearance: CharacterAppearance
    /// How the player first meets them (shown in the relationships of « Mon enquêteur »).
    public var bio: String?
    /// Metres (1.55–1.95).
    public var height: Double?
    /// Width of the silhouette (0.85 slim … 1.15 stocky).
    public var build: Double?
    /// What they wear on top of the outfit: « halfmoon_glasses », « glasses_chain », « tie »,
    /// « lanyard », « headset »…
    public var extras: [String]?

    public var displayName: String { "\(firstName) \(lastName)" }
}
