#if os(iOS)
import Foundation
import CaseEngine

/// The investigation in progress, saved on the device so that leaving the app (or the app being
/// killed) never loses it: the engine's state plus the screen the player was on.
struct SavedInvestigation: Codable {
    var snapshot: InvestigationSnapshot
    var path: [PhoneRoute]

    var remainingSeconds: Double {
        max(0, Double(snapshot.durationSeconds) - snapshot.activeSeconds - snapshot.penaltySeconds)
    }
}

/// Where an investigation in progress is kept. The story mode has its own slot: a case of the
/// campaign never replaces (nor is replaced by) an ENQUÊTES / ALIBI investigation.
enum SaveSlot: String, Sendable {
    case main = "investigation-in-progress.json"
    case story = "story-investigation-in-progress.json"
}

/// One file per slot in Application Support, written atomically.
enum SavedInvestigationStore {
    private static func url(_ slot: SaveSlot) -> URL? {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(slot.rawValue)
    }

    static func load(_ slot: SaveSlot = .main) -> SavedInvestigation? {
        guard let url = url(slot), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SavedInvestigation.self, from: data)
    }

    static func save(_ saved: SavedInvestigation, slot: SaveSlot = .main) {
        guard let url = url(slot), let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func clear(_ slot: SaveSlot = .main) {
        guard let url = url(slot) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
#endif
