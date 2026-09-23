#if os(iOS)
import Foundation

/// Best result per case, kept on the device (UserDefaults). The investigation itself is not
/// saved: a case is short and meant to be replayed from the start.
struct CaseProgress: Codable, Equatable {
    var plays = 0
    var solved = false
    var bestScore = 0
}

enum ProgressStore {
    private static let key = "screenshot.progress.v1"

    static func all() -> [String: CaseProgress] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: CaseProgress].self, from: data) else { return [:] }
        return decoded
    }

    static func record(caseID: String, solved: Bool, score: Int) {
        var progress = all()
        var entry = progress[caseID] ?? CaseProgress()
        entry.plays += 1
        entry.solved = entry.solved || solved
        entry.bestScore = max(entry.bestScore, score)
        progress[caseID] = entry
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
#endif
