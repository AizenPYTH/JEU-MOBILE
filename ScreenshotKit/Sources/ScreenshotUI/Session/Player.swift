#if os(iOS)
import Foundation

// The player's identity and career (final handoff §C, §F-03, §F-12; 06 §0). Predefined characters:
// the player picks who investigates (Élise or Vincent) and one of two photos; nothing else.

/// The two investigators of the Bureau des Enquêtes Numériques.
enum PlayerID: String, CaseIterable, Codable {
    case elise, vincent

    var firstName: String { self == .elise ? "Élise" : "Vincent" }
    var lastName: String { self == .elise ? "Morel" : "Delmas" }
    var fullName: String { firstName + " " + lastName }
    /// « É. MOREL »
    var shortName: String { "\(firstName.prefix(1)). \(lastName.uppercased())" }
    var initials: String { "\(firstName.prefix(1))\(lastName.prefix(1))" }
    /// Fixed service number (06 §0).
    var serviceNumber: String { self == .elise ? "BEN-04821" : "BEN-05307" }
    /// ENQUÊTRICE / ENQUÊTEUR
    var title: String { L10n.t(self == .elise ? "player.titleF" : "player.titleM") }
    var bio: String { L10n.t("player.bio.\(rawValue)") }
    /// « affectée » / « affecté »
    var isFeminine: Bool { self == .elise }
}

enum Appearance: String, CaseIterable, Codable {
    case a, b
}

/// Who investigates, as chosen on screen 03 (saved on the device).
struct PlayerIdentity: Equatable {
    var id: PlayerID
    var appearance: Appearance

    /// `player_elise_a` … — the portrait asset (initials if absent).
    var portraitName: String { "player_\(id.rawValue)_\(appearance.rawValue)" }

    static let `default` = PlayerIdentity(id: .elise, appearance: .a)
}

/// Ranks of the BEN. The threshold is the number of cases solved (06 §0): 0 → ENQUÊTEUR,
/// 1 → INSPECTEUR, 2–3 → SENIOR, 4 and more → EXPÉRIMENTÉ. There is no lower rank.
enum Rank: Int, CaseIterable, Comparable {
    case enqueteur, inspecteur, senior, experimente

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    static func forSolved(_ solved: Int) -> Rank {
        switch solved {
        case ..<1: .enqueteur
        case 1: .inspecteur
        case 2...3: .senior
        default: .experimente
        }
    }

    var title: String { L10n.t("rank.\(key)") }
    /// Inked rank stamp (Art.xcassets/Stamps).
    var stampAsset: String { "stamp_\(key)_rouge" }
    /// Cases to solve to reach the next rank (nil at the top).
    var nextThreshold: Int? {
        switch self {
        case .enqueteur: 1
        case .inspecteur: 2
        case .senior: 4
        case .experimente: nil
        }
    }

    private var key: String {
        switch self {
        case .enqueteur: "enqueteur"
        case .inspecteur: "inspecteur"
        case .senior: "senior"
        case .experimente: "experimente"
        }
    }
}

/// The player's identity and career state, stored in UserDefaults.
enum PlayerStore {
    static let playerKey = "conclude.player"
    static let appearanceKey = "conclude.appearance"
    static let chosenKey = "conclude.playerChosen"
    static let assignedKey = "conclude.assignedToBEN"
    static let assignedDateKey = "conclude.assignedDate"

    /// Who investigates (Élise A until the player chooses).
    static var identity: PlayerIdentity {
        get {
            let defaults = UserDefaults.standard
            return PlayerIdentity(id: PlayerID(rawValue: defaults.string(forKey: playerKey) ?? "") ?? .elise,
                                  appearance: Appearance(rawValue: defaults.string(forKey: appearanceKey) ?? "") ?? .a)
        }
        set {
            // Never blocking: UserDefaults writes do not fail visibly; the value is used in memory anyway.
            UserDefaults.standard.set(newValue.id.rawValue, forKey: playerKey)
            UserDefaults.standard.set(newValue.appearance.rawValue, forKey: appearanceKey)
            UserDefaults.standard.set(true, forKey: chosenKey)
        }
    }

    /// Screen 03 was answered.
    static var hasChosen: Bool { UserDefaults.standard.bool(forKey: chosenKey) }

    /// Screen 12 was shown: the career layer (service number, rank, profile) is visible.
    static var isAssigned: Bool {
        get { UserDefaults.standard.bool(forKey: assignedKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: assignedKey)
            if newValue, UserDefaults.standard.object(forKey: assignedDateKey) == nil {
                UserDefaults.standard.set(Date(), forKey: assignedDateKey)
            }
        }
    }

    static var assignedDate: Date? { UserDefaults.standard.object(forKey: assignedDateKey) as? Date }

    /// Players of earlier versions (they already have finished cases) go straight to the desk,
    /// already assigned, as Élise A until they choose otherwise in their profile.
    static func migrate(attempts: [Attempt]) {
        guard !isAssigned, !attempts.isEmpty else { return }
        isAssigned = true
    }

    /// Screen 12 is due (once): case #001 solved, or failed twice, or filed anyway.
    static func assignmentDue(attempts: [Attempt], firstCaseID: String, filedAnyway: Bool) -> Bool {
        guard !isAssigned else { return false }
        let first = attempts.filter { $0.caseID == firstCaseID }
        return filedAnyway || first.contains { $0.solved } || first.filter { !$0.solved }.count >= 2
    }

    static func reset() {
        for key in [playerKey, appearanceKey, chosenKey, assignedKey, assignedDateKey] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
#endif
