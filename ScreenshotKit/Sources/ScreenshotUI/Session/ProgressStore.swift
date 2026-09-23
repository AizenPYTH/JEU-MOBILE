#if os(iOS)
import Foundation

/// One finished attempt at a case (screen 05 "Dossiers").
struct Attempt: Codable, Equatable, Identifiable {
    var id = UUID()
    var caseID: String
    var date: Date
    var score: Int
    var solved: Bool
    /// False once the solution was revealed after a wrong answer (score "non classé").
    var ranked: Bool
    var found: Int
    var total: Int
    var hintsUsed: Int
}

/// Summary of a case across attempts.
struct CaseProgress: Equatable {
    var plays = 0
    var solved = false
    /// The solution can be read again in the archive (solved, or revealed).
    var archiveOpen = false
    var bestScore = 0
}

/// Attempts kept on the device (UserDefaults). An investigation itself is not saved: a case is short
/// and meant to be replayed from the start.
enum ProgressStore {
    private static let key = "screenshot.attempts.v1"

    static func attempts() -> [Attempt] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Attempt].self, from: data) else { return [] }
        return decoded
    }

    static func summary(of attempts: [Attempt]) -> [String: CaseProgress] {
        var result: [String: CaseProgress] = [:]
        for attempt in attempts {
            var entry = result[attempt.caseID] ?? CaseProgress()
            entry.plays += 1
            entry.solved = entry.solved || attempt.solved
            entry.archiveOpen = entry.archiveOpen || attempt.solved || !attempt.ranked
            if attempt.ranked { entry.bestScore = max(entry.bestScore, attempt.score) }
            result[attempt.caseID] = entry
        }
        return result
    }

    static func record(_ attempt: Attempt) {
        save(attempts() + [attempt])
    }

    /// Marks an attempt as unranked (the player chose to reveal the solution).
    static func markRevealed(_ id: UUID) {
        save(attempts().map { var a = $0; if a.id == id { a.ranked = false }; return a })
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func save(_ attempts: [Attempt]) {
        if let data = try? JSONEncoder().encode(attempts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
#endif
