/// `rules.json` — every tuning number of the game. Designers edit JSON, never Swift.
public struct GameRules: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var timeCosts: TimeCosts
    /// Messages shown when a conversation opens, and per "load older" page.
    public var messagesPageSize: Int
    /// At or below this many seconds the timer turns amber ("low").
    public var lowTimeWarningSeconds: Int
    /// At or below this many seconds the timer turns red ("critical").
    public var criticalTimeSeconds: Int
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

    /// Score out of 100 (handoff §G-35):
    /// `correctSuspect·[right] + found·(found/total) + timeLeft·(remaining/duration)
    ///  + notebookPrecision·(relevant pins/pins) − hint costs`, rounded down, 0…100.
    public struct Scoring: Codable, Sendable, Equatable {
        public var correctSuspect: Int
        public var found: Int
        public var timeLeft: Int
        public var notebookPrecision: Int
    }
}
