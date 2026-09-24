import Foundation

/// Everything the player did in an investigation, saved so it can be resumed after the app was
/// closed. Only the player's own state is stored: what depends on time (live events, notifications,
/// deletions) is recomputed from the elapsed time, so there is a single notion of time.
public struct InvestigationSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var caseID: String
    /// Duration the investigation was started with (it can be shortened in debug builds).
    public var durationSeconds: Int
    public var phase: Investigation.Phase
    public var activeSeconds: Double
    public var penaltySeconds: Double
    public var currentDeviceID: String
    public var seen: Set<ItemRef>
    public var openedApps: Set<AppID>
    public var unlockedApps: Set<AppID>
    public var recoveredMessages: Set<String>
    public var readConversations: Set<String>
    public var loadedPages: [String: Int]
    public var notebook: [NotebookEntry]
    public var marks: [SuspectID: Set<SuspectMark>]
    public var usedHintIDs: [String]
    public var searchCount: Int
    public var readNotifications: Set<String>
    /// Challenge level (absent in games saved by earlier versions: detective).
    public var challenge: Challenge? = nil
}

extension Investigation {
    /// The state to save. Only an investigation still in progress (or waiting for the accusation)
    /// can be resumed.
    public func snapshot() -> InvestigationSnapshot? {
        guard phase == .investigating || phase == .accusing else { return nil }
        return InvestigationSnapshot(
            schemaVersion: InvestigationSnapshot.currentSchemaVersion,
            caseID: caseFile.id,
            durationSeconds: caseFile.durationSeconds,
            phase: phase,
            activeSeconds: activeSeconds,
            penaltySeconds: penaltySeconds,
            currentDeviceID: currentDeviceID,
            seen: seen,
            openedApps: openedApps,
            unlockedApps: unlockedApps,
            recoveredMessages: recoveredMessages,
            readConversations: readConversations,
            loadedPages: loadedPages,
            notebook: notebook,
            marks: marks,
            usedHintIDs: usedHints.map(\.id),
            searchCount: searchCount,
            readNotifications: readNotifications,
            challenge: challenge
        )
    }
}
