/// A challenge level: the same story and the same evidence, with less time.
/// Replaying a case at a harder level is about time and score — never a new story.
public enum Challenge: String, Codable, Sendable, CaseIterable, Hashable, Comparable {
    /// Discover the case (the most time).
    case investigator
    /// The intended challenge.
    case detective
    /// For experienced players (the least time).
    case expert

    public static func < (a: Challenge, b: Challenge) -> Bool {
        (allCases.firstIndex(of: a) ?? 0) < (allCases.firstIndex(of: b) ?? 0)
    }
}

/// How a challenge level is derived from a case (`rules.json`).
public struct ChallengeRule: Codable, Sendable, Equatable {
    public var challenge: Challenge
    /// Duration relative to the case's `durationSeconds`, when the case does not set its own.
    public var durationFactor: Double
    /// Solving the case at this level (or a harder one) unlocks this one; nil = open from the start.
    public var unlockedBy: Challenge?

    public init(challenge: Challenge, durationFactor: Double, unlockedBy: Challenge?) {
        self.challenge = challenge
        self.durationFactor = durationFactor
        self.unlockedBy = unlockedBy
    }
}

extension GameRules {
    /// The challenge levels (defaults when `rules.json` has none).
    public var challengeRules: [ChallengeRule] {
        challenges ?? [
            ChallengeRule(challenge: .investigator, durationFactor: 1.875, unlockedBy: nil),
            ChallengeRule(challenge: .detective, durationFactor: 1, unlockedBy: nil),
            ChallengeRule(challenge: .expert, durationFactor: 0.625, unlockedBy: .detective),
        ]
    }

    public func rule(for challenge: Challenge) -> ChallengeRule? {
        challengeRules.first { $0.challenge == challenge }
    }

    /// Whether a level is playable, given the levels at which the case was already solved.
    /// Solving at a harder level also counts ("solved at detective or harder").
    public func isUnlocked(_ challenge: Challenge, solvedAt: Set<Challenge>) -> Bool {
        guard let required = rule(for: challenge)?.unlockedBy else { return true }
        return solvedAt.contains { $0 >= required }
    }
}

extension CaseFile {
    /// Duration of the case at a challenge level: the case's own value, or the rule's factor applied
    /// to `durationSeconds`, rounded to 30 s.
    public func duration(for challenge: Challenge, rules: GameRules) -> Int {
        if let own = challengeDurations?[challenge.rawValue], own > 0 { return own }
        let factor = rules.rule(for: challenge)?.durationFactor ?? 1
        return max(30, Int((Double(durationSeconds) * factor / 30).rounded()) * 30)
    }

    /// The case as played at a challenge level (only the duration changes).
    public func configured(for challenge: Challenge, rules: GameRules) -> CaseFile {
        var copy = self
        copy.durationSeconds = duration(for: challenge, rules: rules)
        return copy
    }
}
