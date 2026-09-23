/// The outcome of an accusation: never just "right / wrong".
///
/// It tells the player what they got right about the person they accused, what that information
/// really meant, and what they missed — progressively, so they want to replay.
public struct Verdict: Sendable {
    public var accused: SuspectID
    public var isCorrect: Bool
    /// Revealed only if the player asks (or accused the right person): replaying stays interesting.
    public var culprit: SuspectID
    /// Narrative about the accused suspect (from the case file).
    public var accusedText: String
    /// Things the player really found about the accused, with their true meaning.
    public var foundAboutAccused: [Evidence]
    /// Key evidence the player never saw.
    public var missedKey: [Evidence]
    public var foundKeyCount: Int
    public var totalKeyCount: Int
    public var foundSupportingCount: Int
    public var totalSupportingCount: Int
    /// False leads the player uncovered (not a fault by itself).
    public var falseLeadsSeen: [Evidence]
    public var remainingSeconds: Int
    public var hintsUsed: Int
    public var appsOpened: Int
    public var searches: Int
    public var score: Int
    public var scoreParts: ScoreParts

    public struct ScoreParts: Sendable, Equatable {
        public var suspect: Int
        public var keyEvidence: Int
        public var supportingEvidence: Int
        public var time: Int
        public var hintPenalty: Int
        public var falseLeadPenalty: Int
    }

    static func make(for investigation: Investigation, accused: SuspectID) -> Verdict {
        let file = investigation.caseFile
        let rules = investigation.rules.scoring
        let isCorrect = accused == file.solution.culprit
        let found = Set(investigation.foundEvidence.map(\.id))

        let key = file.evidence.filter { $0.importance == .key }
        let supporting = file.evidence.filter { $0.importance == .supporting }
        let falseLeads = file.evidence.filter { $0.importance == .falseLead }
        let foundKey = key.filter { found.contains($0.id) }
        let foundSupporting = supporting.filter { found.contains($0.id) }

        let pinnedOnAccused = Set(investigation.pins[accused] ?? [])
        let falseLeadsPinned = falseLeads.filter { lead in lead.refs.contains { pinnedOnAccused.contains($0) } }

        let remaining = Int(investigation.remainingSeconds.rounded(.down))
        func ratio(_ part: Int, _ total: Int) -> Double { total == 0 ? 1 : Double(part) / Double(total) }

        let parts = ScoreParts(
            suspect: isCorrect ? rules.correctSuspect : 0,
            keyEvidence: Int((ratio(foundKey.count, key.count) * Double(rules.keyEvidence)).rounded()),
            supportingEvidence: Int((ratio(foundSupporting.count, supporting.count) * Double(rules.supportingEvidence)).rounded()),
            // Time left only rewards a correct answer: guessing fast must not pay.
            time: isCorrect ? Int((Double(remaining) / investigation.durationSeconds * Double(rules.timeLeft)).rounded()) : 0,
            hintPenalty: investigation.usedHints.count * rules.hintPenalty,
            falseLeadPenalty: falseLeadsPinned.count * rules.falseLeadPenalty
        )
        let total = parts.suspect + parts.keyEvidence + parts.supportingEvidence + parts.time
            - parts.hintPenalty - parts.falseLeadPenalty

        return Verdict(
            accused: accused,
            isCorrect: isCorrect,
            culprit: file.solution.culprit,
            accusedText: investigation.index.suspect(accused)?.verdict ?? "",
            foundAboutAccused: file.evidence.filter { found.contains($0.id) && $0.suspects.contains(accused) },
            missedKey: key.filter { !found.contains($0.id) },
            foundKeyCount: foundKey.count,
            totalKeyCount: key.count,
            foundSupportingCount: foundSupporting.count,
            totalSupportingCount: supporting.count,
            falseLeadsSeen: falseLeads.filter { found.contains($0.id) },
            remainingSeconds: remaining,
            hintsUsed: investigation.usedHints.count,
            appsOpened: investigation.openedApps.count,
            searches: investigation.searchCount,
            score: min(100, max(0, total)),
            scoreParts: parts
        )
    }
}
