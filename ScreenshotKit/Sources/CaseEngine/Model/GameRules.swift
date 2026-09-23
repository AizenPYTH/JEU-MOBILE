/// `rules.json` — every tuning number of the game. Designers edit JSON, never Swift.
public struct GameRules: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var timeCosts: TimeCosts
    /// Messages shown when a conversation opens, and per "load older" page.
    public var messagesPageSize: Int
    /// Below this many seconds the timer turns to alert.
    public var lowTimeWarningSeconds: Int
    /// How long a notification banner stays on screen.
    public var bannerSeconds: Double
    public var scoring: Scoring

    /// Seconds removed from the timer by each action — reading, searching and analysing cost time.
    public struct TimeCosts: Codable, Sendable, Equatable {
        public var openApp: Int
        public var openConversation: Int
        public var loadOlderMessages: Int
        public var search: Int
        public var openPhoto: Int
        public var analyzePhoto: Int
        public var openTrack: Int
        public var openCalendarEvent: Int
        public var openNote: Int
        public var openMail: Int
        public var openBrowserEntry: Int
        public var openContact: Int
        public var recoverMessage: Int
        public var unlockAttempt: Int
    }

    /// Score out of 100.
    public struct Scoring: Codable, Sendable, Equatable {
        /// Points for accusing the right suspect.
        public var correctSuspect: Int
        /// Points for finding all key evidence (pro rata).
        public var keyEvidence: Int
        /// Points for time left (pro rata of the case duration).
        public var timeLeft: Int
        /// Points for supporting evidence (pro rata).
        public var supportingEvidence: Int
        /// Removed per hint used.
        public var hintPenalty: Int
        /// Removed per false lead pinned on the accused suspect.
        public var falseLeadPenalty: Int
    }
}
