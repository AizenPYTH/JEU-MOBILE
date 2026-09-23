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

/// One file in Application Support, written atomically.
enum SavedInvestigationStore {
    private static var url: URL? {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("investigation-in-progress.json")
    }

    static func load() -> SavedInvestigation? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SavedInvestigation.self, from: data)
    }

    static func save(_ saved: SavedInvestigation) {
        guard let url, let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func clear() {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
#endif
