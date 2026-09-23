/// The outcome of an accusation: never just "right / wrong".
///
/// Right: the reconstruction, with what the player found (●) and missed (○).
/// Wrong: why the accused is innocent (alibi), why they looked guilty (the trap), and how many
/// things were missed *per app* — without saying which, so replaying stays interesting.
public struct Verdict: Sendable {
    public var accused: SuspectID
    public var isCorrect: Bool
    public var culprit: SuspectID
    /// Narrative about the accused suspect.
    public var accusedText: String
    public var alibi: String?
    public var alibiEvidence: Evidence?
    public var trap: String?
    /// Things the player really found about the accused, with their true meaning.
    public var foundAboutAccused: [Evidence]
    /// Key + supporting evidence the player never saw.
    public var missed: [Evidence]
    /// How many missed items per app (the wrong-answer screen shows counts only).
    public var missedByApp: [AppID: Int]
    public var foundCount: Int
    public var totalCount: Int
    public var foundEvidenceIDs: Set<String>
    public var falseLeadsSeen: [Evidence]
    public var pinnedCount: Int
    public var relevantPinnedCount: Int
    public var remainingSeconds: Int
    public var hintsUsed: Int
    public var hintCost: Int
    public var appsOpened: Int
    public var searches: Int
    public var score: Int
    public var scoreParts: ScoreParts

    /// 100 % = "Parfaite".
    public var isPerfect: Bool { score >= 100 }

    public struct ScoreParts: Sendable, Equatable {
        public var suspect: Int
        public var found: Int
        public var time: Int
        public var precision: Int
        public var hintCost: Int
    }

    static func make(for investigation: Investigation, accused: SuspectID) -> Verdict {
        let file = investigation.caseFile
        let scoring = investigation.rules.scoring
        let isCorrect = accused == file.solution.culprit
        let foundIDs = Set(investigation.foundEvidence.map(\.id))

        let counted = file.evidence.filter { $0.importance != .falseLead }
        let found = counted.filter { foundIDs.contains($0.id) }
        let missed = counted.filter { !foundIDs.contains($0.id) }

        // Notebook precision: pinned items that belong to real (non-false-lead) evidence.
        let relevantRefs = Set(counted.flatMap(\.refs))
        let pinned = investigation.notebook.map(\.ref)
        let relevantPinned = pinned.filter { ref in
            relevantRefs.contains(ref) || (ref.kind == .photo && relevantRefs.contains(ItemRef(.photoInfo, ref.id)))
        }

        let remaining = Int(investigation.remainingSeconds.rounded(.down))
        func ratio(_ part: Int, _ total: Int) -> Double { total == 0 ? 0 : Double(part) / Double(total) }
        let parts = ScoreParts(
            suspect: isCorrect ? scoring.correctSuspect : 0,
            found: Int(ratio(found.count, counted.count) * Double(scoring.found)),
            // Time left only rewards a correct answer: guessing fast must not pay.
            time: isCorrect ? Int(Double(remaining) / investigation.durationSeconds * Double(scoring.timeLeft)) : 0,
            precision: Int(ratio(relevantPinned.count, pinned.count) * Double(scoring.notebookPrecision)),
            hintCost: investigation.hintScoreCost
        )
        let total = parts.suspect + parts.found + parts.time + parts.precision - parts.hintCost

        var missedByApp: [AppID: Int] = [:]
        for evidence in missed {
            guard let ref = evidence.refs.first else { continue }
            let deleted = ref.kind == .message && investigation.index.message(ref.id)?.deletedAt != nil
            missedByApp[deleted ? .trash : ref.kind.app, default: 0] += 1
        }

        let suspect = investigation.index.suspect(accused)
        return Verdict(
            accused: accused,
            isCorrect: isCorrect,
            culprit: file.solution.culprit,
            accusedText: suspect?.verdict ?? "",
            alibi: suspect?.alibi,
            alibiEvidence: suspect?.alibiEvidence.flatMap { id in file.evidence.first { $0.id == id } },
            trap: suspect?.trap,
            foundAboutAccused: file.evidence.filter { foundIDs.contains($0.id) && $0.suspects.contains(accused) },
            missed: missed,
            missedByApp: missedByApp,
            foundCount: found.count,
            totalCount: counted.count,
            foundEvidenceIDs: foundIDs,
            falseLeadsSeen: file.evidence.filter { $0.importance == .falseLead && foundIDs.contains($0.id) },
            pinnedCount: pinned.count,
            relevantPinnedCount: relevantPinned.count,
            remainingSeconds: remaining,
            hintsUsed: investigation.usedHints.count,
            hintCost: investigation.hintScoreCost,
            appsOpened: investigation.openedApps.count,
            searches: investigation.searchCount,
            score: min(100, max(0, total)),
            scoreParts: parts
        )
    }
}

extension ItemRef.Kind {
    /// The app an item lives in.
    public var app: AppID {
        switch self {
        case .message, .draft: .messages
        case .call: .phone
        case .photo, .photoInfo: .photos
        case .track: .location
        case .calendar: .calendar
        case .note: .notes
        case .mail: .mail
        case .browser: .browser
        case .contact: .contacts
        case .app: .settings
        }
    }
}
