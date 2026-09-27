import Foundation
import Testing
@testable import CaseEngine

/// The ALIBI mode: one person, one claim, « confirmé » or « contredit ».
@Suite("ALIBI mode")
struct AlibiTests {
    /// The fixture case turned into an ALIBI check: Emma claims she stayed home, the phone contradicts it.
    static var alibiCase: CaseFile {
        var file = Fixtures.caseFile
        file.id = "alibi_test"
        file.number = 199
        file.mode = .alibi
        file.claim = AlibiClaim(person: "emma", statement: "« Je suis restée chez moi. »", place: "Chez elle",
                                from: Fixtures.m("2026-09-12 21:00"), to: Fixtures.m("2026-09-12 23:00"))
        file.suspects = [file.suspects[1]]
        file.evidence = file.evidence.map { e in
            var e = e
            if e.suspects == ["s_lucas"] { e.suspects = ["s_emma"] }
            return e
        }
        file.solution.alibiHolds = false
        file.minimalPath = ["ev_rdv", "ev_photo"]
        return file
    }

    static func game(_ file: CaseFile = alibiCase) -> Investigation {
        let game = Investigation(caseFile: file, rules: Fixtures.rules, clock: ManualClock(start: Date(timeIntervalSince1970: 0)))
        game.start()
        return game
    }

    @Test func aValidAlibiCase() {
        #expect(CaseValidator.validate(Self.alibiCase).isEmpty)
    }

    @Test func alibiRulesAreChecked() {
        var two = Self.alibiCase
        two.suspects = Fixtures.caseFile.suspects
        #expect(CaseValidator.validate(two).contains { $0.message.contains("exactly one person") })

        var noAnswer = Self.alibiCase
        noAnswer.solution.alibiHolds = nil
        #expect(CaseValidator.validate(noAnswer).contains { $0.message.contains("alibiHolds") })

        var noClaim = Self.alibiCase
        noClaim.claim = nil
        #expect(CaseValidator.validate(noClaim).contains { $0.message.contains("claim") })

        var mainWithClaim = Fixtures.caseFile
        mainWithClaim.claim = Self.alibiCase.claim
        #expect(CaseValidator.validate(mainWithClaim).contains { $0.message.contains("belong to ALIBI") })
    }

    @Test func minimalPathIsChecked() {
        var file = Fixtures.caseFile
        file.minimalPath = ["ev_rdv", "ev_photo"]
        #expect(CaseValidator.validate(file).isEmpty)
        file.minimalPath = ["ev_rdv", "ev_lucas"]
        let issues = CaseValidator.validate(file).map(\.message)
        #expect(issues.contains { $0.contains("false lead") })
        #expect(issues.contains { $0.contains("at least 2 key") })
        file.minimalPath = ["nope"]
        #expect(CaseValidator.validate(file).contains { $0.message.contains("unknown evidence 'nope'") })
    }

    @Test func theRightAnswerWins() {
        let game = Self.game()
        let verdict = game.concludeAlibi(holds: false)
        #expect(verdict?.isCorrect == true)
        #expect(verdict?.alibiAnswer == false)
        #expect(game.phase == .finished)
        #expect((verdict?.scoreParts.suspect ?? 0) > 0)
    }

    @Test func theWrongAnswerLoses() {
        let verdict = Self.game().concludeAlibi(holds: true)
        #expect(verdict?.isCorrect == false)
        #expect(verdict?.scoreParts.suspect == 0)
        #expect(verdict?.scoreParts.time == 0)
    }

    @Test func modesDoNotMix() {
        // No « who is responsible » in an ALIBI case, no alibi answer in an investigation.
        #expect(Self.game().accuse("s_emma") == nil)
        #expect(Self.game(Fixtures.caseFile).concludeAlibi(holds: true) == nil)
    }

    @Test func minimalPathEstimate() {
        let report = CaseAnalysis.analyze(Self.alibiCase, rules: Fixtures.rules)
        #expect(report.minimalPathSeconds != nil)
        #expect(report.minimalPathSeconds! <= report.estimatedSolveSeconds + 60)
        #expect(CaseAnalysis.analyze(Fixtures.caseFile, rules: Fixtures.rules).minimalPathSeconds == nil)
    }
}
