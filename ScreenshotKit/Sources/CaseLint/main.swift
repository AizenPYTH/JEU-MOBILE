import Foundation
import CaseEngine
import CaseLibrary

// CaseLint — checks every case shipped with the game.
//
//   swift run CaseLint
//
// For each case: loads it, validates every reference, and checks it can be solved in time.
// Exit code 1 if anything is wrong (used by CI).

var failed = false
do {
    let rules = try CaseLibrary.loadRules()
    let cases = try CaseLibrary.loadCases()
    print("SCREENSHOT CaseLint — CaseEngine \(CaseEngine.version) — \(cases.count) case(s)\n")
    for file in cases {
        let issues = CaseValidator.validate(file)
        let report = CaseAnalysis.analyze(file, rules: rules)
        let minutes = file.durationSeconds / 60, seconds = file.durationSeconds % 60
        print("#\(String(format: "%03d", file.number)) \(file.title)  (\(minutes):\(String(format: "%02d", seconds)), difficulty \(file.difficulty))")
        print("  suspects: \(file.suspects.count) · evidence: \(file.evidence.count) (key \(report.keyEvidenceCount)) · hints: \(file.hints.count)")
        print("  messages: \(report.messageCount) · photos: \(report.photoCount) · noise: \(Int(report.noiseRatio * 100)) % of messages are not evidence")
        print("  minimum action cost to see all key evidence: \(report.minimumKeyCost) s · estimated solve time: \(report.estimatedSolveSeconds) s")
        if !report.isComfortablySolvable {
            print("  ⚠️  estimated solve time is above 75 % of the duration")
        }
        if issues.isEmpty {
            print("  ✓ valid\n")
        } else {
            failed = true
            issues.forEach { print("  ✗ \($0.message)") }
            print("")
        }
    }
} catch {
    print("Failed to load cases: \(error)")
    failed = true
}
exit(failed ? 1 : 0)
