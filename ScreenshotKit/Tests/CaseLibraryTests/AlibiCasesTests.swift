import Foundation
import Testing
import CaseEngine
import CaseLibrary

/// The ALIBI checks shipped with the game (docs/game_modes/ALIBI.md): short, one person, one claim,
/// fair — and played to the end through the engine.
@Suite("ALIBI checks")
struct AlibiCasesTests {
    static func alibis() throws -> [CaseFile] { try CaseLibrary.loadCases().filter(\.isAlibi) }

    @Test func threeChecksAtLaunch() throws {
        let files = try Self.alibis()
        #expect(files.map(\.id) == ["alibi_001", "alibi_002", "alibi_003"])
        #expect(files.map(\.number) == [101, 102, 103])
        // Never « always contradicted »: both answers exist.
        let answers = Set(files.compactMap(\.solution.alibiHolds))
        #expect(answers == [true, false])
        // They get harder: the first is the simplest.
        #expect(files.map(\.difficulty) == files.map(\.difficulty).sorted())
    }

    @Test func shortAndSimple() throws {
        let rules = try CaseLibrary.loadRules()
        for file in try Self.alibis() {
            #expect((240...360).contains(file.durationSeconds), "\(file.id): \(file.durationSeconds) s")
            #expect(file.suspects.count == 1 && file.devices.count == 1, "\(file.id)")
            #expect(file.introScene == nil, "\(file.id): no opening scene")
            #expect(file.hints.map(\.scoreCost) == [0, 5, 10], "\(file.id)")
            let key = file.evidence.filter { $0.importance == .key }
            #expect((2...5).contains(key.count), "\(file.id): \(key.count) key pieces")
            let path = try #require(file.minimalPath, "\(file.id)")
            #expect((2...4).contains(path.count), "\(file.id)")
            let seconds = try #require(CaseAnalysis.analyze(file, rules: rules).minimalPathSeconds)
            #expect(seconds <= file.durationSeconds / 2, "\(file.id): \(seconds) s for the essentials")
            #expect(file.claim?.person == file.suspects.first?.contact, "\(file.id)")
            // The answer is never in a hint.
            for hint in file.hints {
                let text = hint.text.lowercased()
                #expect(!text.contains("confirmé") && !text.contains("contredit"), "\(file.id): \(hint.id) gives the answer")
            }
        }
    }

    /// Finding the essentials and answering right wins; the wrong answer loses.
    @Test func playedToTheEnd() throws {
        let rules = try CaseLibrary.loadRules()
        for file in try Self.alibis() {
            let holds = try #require(file.solution.alibiHolds)
            for answer in [holds, !holds] {
                let game = Investigation(caseFile: file, rules: rules, clock: ManualClock(start: Date(timeIntervalSince1970: 0)))
                game.start()
                for evidence in file.evidence where file.minimalPath?.contains(evidence.id) == true {
                    for ref in evidence.refs {
                        game.markSeen(ref)
                        if evidence.anyOf == true { break }
                    }
                    if let first = evidence.refs.first { _ = game.togglePin(first) }
                }
                let verdict = try #require(game.concludeAlibi(holds: answer))
                #expect(verdict.isCorrect == (answer == holds), "\(file.id)")
                if answer == holds {
                    #expect(verdict.score >= 60, "\(file.id): \(verdict.score)")
                    #expect(verdict.foundCount >= 2, "\(file.id)")
                } else {
                    #expect(verdict.score < 40, "\(file.id): \(verdict.score)")
                }
            }
        }
    }
}
