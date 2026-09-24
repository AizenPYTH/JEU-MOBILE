import Foundation
import CaseEngine
import CaseLibrary

// CaseLint — checks every case shipped with the game.
//
//   swift run CaseLint
//
//   swift run CaseLint --rules path/to/rules.json path/to/case_002.json …
//
// For each case: loads it, validates every reference, and checks it can be solved in time.
// With file arguments, checks those files instead of the shipped cases (to try a case before adding it).
// Exit code 1 if anything is wrong (used by CI).

var failed = false
do {
    var arguments = Array(CommandLine.arguments.dropFirst())
    var rulesPath: String?
    if let i = arguments.firstIndex(of: "--rules"), i + 1 < arguments.count {
        rulesPath = arguments[i + 1]
        arguments.removeSubrange(i...(i + 1))
    }
    let rules = try rulesPath.map { try CaseLoader.loadRules(Data(contentsOf: URL(fileURLWithPath: $0))) } ?? CaseLibrary.loadRules()
    let cases = arguments.isEmpty
        ? try CaseLibrary.loadCases()
        : try arguments.map { path in
            let url = URL(fileURLWithPath: path)
            return try CaseLoader.loadCase(Data(contentsOf: url), name: url.lastPathComponent)
        }
    print("TRACE CaseLint — CaseEngine \(CaseEngine.version) — \(cases.count) case(s)\n")
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
        let levels = Challenge.allCases.map { level -> String in
            let d = file.duration(for: level, rules: rules)
            return "\(level.rawValue) \(d / 60):\(String(format: "%02d", d % 60))"
        }
        print("  challenges: " + levels.joined(separator: " · "))
        if let shortest = Challenge.allCases.map({ file.duration(for: $0, rules: rules) }).min(),
           report.estimatedSolveSeconds > shortest * 3 / 4 {
            print("  ✗ not solvable at the hardest level (\(report.estimatedSolveSeconds) s for \(shortest) s)")
            failed = true
        }
        if let intro = file.introScene {
            print("  intro: \(intro.shots.count) shots · \(Int(intro.totalSeconds)) s")
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
