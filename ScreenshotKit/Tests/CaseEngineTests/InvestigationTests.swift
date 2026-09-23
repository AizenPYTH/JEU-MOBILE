import Foundation
import Testing
@testable import CaseEngine

@Suite("Investigation — timer")
struct TimerTests {
    @Test func countdownStartsAfterBriefing() {
        let (game, clock) = Fixtures.investigation()
        clock.advance(by: 50)
        game.tick()
        #expect(game.remainingSeconds == 300) // still in briefing
        game.start()
        for _ in 0..<40 { clock.advance(by: 0.25); game.tick() }
        #expect(game.remainingSeconds == 290)
        #expect(game.phoneNow.description == "2026-09-13 10:00:10")
    }

    @Test func actionsCostTime() {
        let (game, _) = Fixtures.investigation()
        game.start()
        game.openApp(.messages)
        game.openConversation("c_lucas")
        _ = game.search("22h")
        #expect(game.remainingSeconds == 300 - 1 - 3 - 8)
        let spent = game.drainEvents().compactMap { if case .timeSpent(let s, _) = $0 { s } else { nil } }
        #expect(spent == [1, 3, 8])
    }

    @Test func pauseStopsTheClockAndHugeJumpsAreCapped() {
        let (game, clock) = Fixtures.investigation()
        game.start()
        game.pause()
        clock.advance(by: 3_600)
        game.tick()
        #expect(game.remainingSeconds == 300)
        game.resume()
        clock.advance(by: 500) // app suspended without pause: never punish more than 2 s
        game.tick()
        #expect(game.remainingSeconds == 298)
    }

    @Test func accusingEarlyCanBeCancelledWhileTimeRemains() {
        let (game, clock) = Fixtures.investigation()
        game.start()
        game.requestAccusation()
        #expect(game.phase == .accusing)
        clock.advance(by: 30); game.tick() // the timer is stopped on the accusation screen
        game.cancelAccusation()
        #expect(game.phase == .investigating)
        #expect(game.remainingSeconds == 300)
    }

    @Test func clockGoingBackwardsIsHarmless() {
        let (game, clock) = Fixtures.investigation()
        game.start()
        clock.set(clock.now.addingTimeInterval(-1_000))
        game.tick()
        #expect(game.remainingSeconds == 300)
    }

    @Test func reachingZeroForcesTheAccusation() {
        let (game, clock) = Fixtures.investigation()
        game.start()
        var events: [InvestigationEvent] = []
        for _ in 0..<(310 * 4) { clock.advance(by: 0.25); game.tick(); events += game.drainEvents() }
        #expect(game.remainingSeconds == 0)
        #expect(game.phase == .accusing)
        #expect(events.contains(.lowTime))
        #expect(events.contains(.timeUp))
        // Actions no longer cost anything once time is up.
        game.openApp(.photos)
        #expect(game.penaltySeconds == 0)
        // …but the player can still (and must) accuse.
        #expect(game.accuse("s_emma")?.isCorrect == true)
    }
}

@Suite("Investigation — phone content")
struct PhoneContentTests {
    @Test func deletedMessagesOnlyAppearOnceRecovered() {
        let (game, _) = Fixtures.investigation()
        game.start()
        #expect(game.visibleMessages(in: "c_emma").map(\.id) == ["e2"])
        #expect(game.trash.map(\.id) == ["e1"])
        game.recoverMessage("e1")
        #expect(game.visibleMessages(in: "c_emma").map(\.id) == ["e1", "e2"])
        #expect(game.visibleMessages(in: "c_emma").first?.state == .recovered)
        #expect(game.trash.first?.isRecovered == true)
        #expect(game.remainingSeconds == 300 - 12)
    }

    @Test func conversationsLoadPageByPage() {
        let (game, _) = Fixtures.investigation()
        game.start()
        game.openConversation("c_lucas")
        #expect(game.loadedMessages(in: "c_lucas").map(\.id) == ["l3", "l4", "l5"])
        #expect(game.hasOlderMessages(in: "c_lucas"))
        game.loadOlderMessages(in: "c_lucas")
        #expect(game.loadedMessages(in: "c_lucas").count == 5)
        #expect(!game.hasOlderMessages(in: "c_lucas"))
    }

    @Test func liveEventsArriveDuringTheInvestigation() {
        let (game, clock) = Fixtures.investigation()
        game.start()
        #expect(game.notifications.isEmpty)
        clock.advance(by: 1); game.tick()
        game.openApp(.photos) // time costs also move the phone forward
        for _ in 0..<30 { clock.advance(by: 1); game.tick() }
        let events = game.drainEvents()
        #expect(events.contains { if case .notification(let n) = $0 { n.id == "lv1" } else { false } })
        #expect(game.visibleMessages(in: "c_lucas").last?.message.text == "Réponds stp")
        #expect(game.visibleMessages(in: "c_lucas").last?.isLive == true)
        #expect(game.unreadCount(in: "c_lucas") >= 1)
        // Live messages are timestamped when they arrive, on the phone's clock.
        #expect(game.visibleMessages(in: "c_lucas").last?.message.at.description == "2026-09-13 10:00:30")
    }

    @Test func thePhoneClockFollowsTheTimer() {
        let (game, clock) = Fixtures.investigation()
        game.start()
        #expect(game.phoneNow == game.caseFile.phoneStartTime)
        for _ in 0..<50 { clock.advance(by: 1); game.tick() }
        game.openApp(.photos)
        game.analyzePhoto("p1") // time costs move the phone's clock too
        let spent = game.durationSeconds - game.remainingSeconds
        #expect(game.phoneNow == game.caseFile.phoneStartTime.adding(seconds: Int64(spent)))
        #expect(game.phoneNow.clockText == "10:01")
        // Paused: neither the timer nor the phone's clock move.
        game.pause()
        let before = game.phoneNow
        clock.advance(by: 120); game.tick()
        #expect(game.phoneNow == before)
    }

    @Test func senderDeletionLeavesATombstone() {
        let (game, clock) = Fixtures.investigation()
        game.start()
        for _ in 0..<61 { clock.advance(by: 1); game.tick() }
        let l5 = game.visibleMessages(in: "c_lucas").first { $0.id == "l5" }
        #expect(l5?.state == .removedBySender)
    }

    @Test func lockedAppsNeedTheCode() {
        let (game, _) = Fixtures.investigation()
        game.start()
        #expect(game.openApp(.notes) == .locked)
        #expect(!game.unlock(.notes, code: "0000"))
        #expect(game.unlock(.notes, code: "1609"))
        #expect(game.openApp(.notes) == .open)
        #expect(game.remainingSeconds == 300 - 5 - 5 - 1)
    }

    @Test func photosAreSortedByTheirRealDateAndAnalysisIsPaidOnce() {
        let (game, _) = Fixtures.investigation()
        game.start()
        game.openPhoto("p1")
        game.analyzePhoto("p1")
        game.analyzePhoto("p1")
        #expect(game.isAnalyzed("p1"))
        #expect(game.remainingSeconds == 300 - 2 - 15)
    }
}

@Suite("Message search")
struct SearchTests {
    private func ids(_ query: String) -> [String] {
        let (game, _) = Fixtures.investigation()
        game.start()
        game.recoverMessage("e1")
        return game.search(query).map(\.id)
    }

    @Test func findsWordsIgnoringCaseAndAccents() {
        #expect(ids("MAISON") == ["l2"])
        #expect(ids("restee") == ["e2"])
    }

    @Test func findsContacts() {
        #expect(Set(ids("lucas")) == ["l1", "l3", "l5"])
    }

    @Test func findsTimesInTextAndTimestamps() {
        // "22h" in the text (l4, e1) + messages sent between 22:00 and 22:59 (l5, e2).
        #expect(Set(ids("22h")) == ["l4", "e1", "l5", "e2"])
        #expect(ids("22:17") == ["l5"])
    }

    @Test func findsDates() {
        #expect(Set(ids("12/09")) == ["l3", "l4", "l5", "e1", "e2"])
        #expect(ids("1 sept") == ["l1"])
    }

    @Test func deletedMessagesAreNotSearchableUntilRecovered() {
        let (game, _) = Fixtures.investigation()
        game.start()
        #expect(game.search("Quai").isEmpty)
    }

    @Test func emptyQueryIsFree() {
        let (game, _) = Fixtures.investigation()
        game.start()
        #expect(game.search("   ").isEmpty)
        #expect(game.penaltySeconds == 0)
    }
}

@Suite("Accusation and score")
struct VerdictTests {
    @Test func rightAnswerWithEvidence() throws {
        let (game, _) = Fixtures.investigation()
        game.start()
        game.recoverMessage("e1")
        game.openPhoto("p1")
        game.analyzePhoto("p1")
        game.togglePin(ItemRef(.message, "e1"))
        game.togglePin(ItemRef(.photo, "p1")) // the pinned photo covers its analysis
        let verdict = try #require(game.accuse("s_emma"))
        #expect(verdict.isCorrect)
        // 3 counted items (2 key + 1 supporting); the draft was never seen.
        #expect(verdict.foundCount == 2 && verdict.totalCount == 3)
        #expect(verdict.missed.map(\.id) == ["ev_draft"])
        #expect(verdict.scoreParts.suspect == 60)
        #expect(verdict.scoreParts.found == 16) // 25 × 2/3, rounded down
        #expect(verdict.scoreParts.precision == 5) // 2 relevant pins out of 2
        #expect(verdict.score == 60 + 16 + verdict.scoreParts.time + 5)
        #expect(game.phase == .finished)
    }

    @Test func seeingIsNotFinding() throws {
        let (game, _) = Fixtures.investigation()
        game.start()
        game.recoverMessage("e1")
        game.openPhoto("p1")
        game.analyzePhoto("p1")
        let evidence = try #require(game.caseFile.evidence.first { $0.id == "ev_photo" })
        #expect(game.isSeen(evidence) && !game.isFound(evidence))
        game.togglePin(ItemRef(.photoInfo, "p1"))
        #expect(game.isFound(evidence))
        game.togglePin(ItemRef(.photoInfo, "p1"))
        #expect(!game.isFound(evidence)) // un-pinning takes it back
        #expect(try #require(game.accuse("s_emma")).foundCount == 0)
    }

    @Test func wrongAnswerExplainsInsteadOfJudging() throws {
        let (game, _) = Fixtures.investigation()
        game.start()
        game.openConversation("c_lucas")
        game.markSeen(ItemRef(.message, "l3"))
        game.link(ItemRef(.message, "l3"), to: "s_lucas")
        let verdict = try #require(game.accuse("s_lucas"))
        #expect(!verdict.isCorrect)
        #expect(verdict.accusedText == "Lucas n'y est pour rien.")
        #expect(verdict.alibi == "Il était reparti." && verdict.trap == "Il était au port.")
        #expect(verdict.alibiEvidence?.id == "ev_draft")
        #expect(verdict.foundAboutAccused.map(\.id) == ["ev_lucas"]) // what they did get right
        #expect(verdict.missedByApp[.trash] == 1 && verdict.missedByApp[.photos] == 1 && verdict.missedByApp[.messages] == 1)
        #expect(verdict.scoreParts.time == 0) // guessing fast must not pay
        #expect(verdict.scoreParts.precision == 0) // the only pin was a false lead
    }

    @Test func hintsAreTieredAndCostScoreNotTime() throws {
        let (game, clock) = Fixtures.investigation()
        game.start()
        #expect(game.useHint()?.id == "h1")
        #expect(game.useHint()?.id == "h2")
        #expect(game.useHint() == nil) // h3 unlocks at 02:00
        #expect(game.remainingSeconds == 300) // hints never cost time
        for _ in 0..<(181 * 4) { clock.advance(by: 0.25); game.tick() }
        #expect(game.state(of: game.caseFile.hints[2]) == .available)
        #expect(game.useHint()?.id == "h3")
        #expect(try #require(game.accuse("s_emma")).scoreParts.hintCost == 23)
    }

    @Test func theNotebookPinsAndLinks() {
        let (game, _) = Fixtures.investigation()
        #expect(game.togglePin(ItemRef(.photoInfo, "p1")))
        #expect(game.isPinned(ItemRef(.photoInfo, "p1")))
        game.link(ItemRef(.photoInfo, "p1"), to: "s_emma")
        game.link(ItemRef(.message, "l3"), to: "s_lucas") // linking pins too
        #expect(game.notebook.count == 2)
        #expect(game.linkedEntries(for: "s_emma").map(\.ref) == [ItemRef(.photoInfo, "p1")])
        #expect(!game.togglePin(ItemRef(.photoInfo, "p1")))
        #expect(game.linkedEntries(for: "s_emma").isEmpty)
        game.toggle(.liedAboutAlibi, for: "s_emma")
        #expect(game.marks["s_emma"] == [.liedAboutAlibi])
    }
}

@Suite("Case validation")
struct ValidatorTests {
    @Test func fixtureIsValid() {
        // The fixture only has 2 key pieces of evidence for the culprit: exactly the minimum.
        #expect(CaseValidator.validate(Fixtures.caseFile).isEmpty)
    }

    @Test func detectsBrokenReferences() {
        var file = Fixtures.caseFile
        file.solution.culprit = "s_nobody"
        file.evidence[0].refs.append(ItemRef(.photo, "p_missing"))
        file.devices[0].conversations[0].messages.append(
            Message(id: "l1", from: "ghost", at: Moment("2026-09-12 10:00")!, text: "?"))
        let messages = CaseValidator.validate(file).map(\.message)
        #expect(messages.contains { $0.contains("culprit") })
        #expect(messages.contains { $0.contains("unknown 'photo:p_missing'") })
        #expect(messages.contains { $0.contains("duplicate id 'l1'") })
        #expect(messages.contains { $0.contains("unknown contact 'ghost'") })
    }

    @Test func itemRefsRoundTrip() throws {
        let ref = try #require(ItemRef("photoInfo:p_emma_couch"))
        #expect(ref.kind == .photoInfo && ref.id == "p_emma_couch")
        #expect(ItemRef("nope:x") == nil)
        let data = try JSONEncoder().encode([ref])
        #expect(try JSONDecoder().decode([ItemRef].self, from: data) == [ref])
    }
}

@Suite("Resuming an investigation")
struct ResumeTests {
    @Test func aSavedInvestigationResumesExactlyWhereItWas() throws {
        let (game, clock) = Fixtures.investigation()
        game.start()
        for _ in 0..<40 { clock.advance(by: 1); game.tick() }
        game.openApp(.messages)
        game.recoverMessage("e1")
        game.openPhoto("p1")
        game.analyzePhoto("p1")
        game.togglePin(ItemRef(.message, "e1"))
        game.link(ItemRef(.photoInfo, "p1"), to: "s_emma")
        game.toggle(.liedAboutAlibi, for: "s_emma")
        _ = game.useHint()
        _ = game.unlock(.notes, code: "1609")
        game.pause() // the app goes to the background

        // Saved as JSON, then the app is killed.
        let saved = try #require(game.snapshot())
        let data = try JSONEncoder().encode(saved)
        let decoded = try JSONDecoder().decode(InvestigationSnapshot.self, from: data)
        #expect(decoded == saved)

        // Relaunched much later: time spent away does not count.
        let laterClock = ManualClock(start: clock.now.addingTimeInterval(3_600))
        let resumed = try #require(Investigation(restoring: decoded, caseFile: game.caseFile, rules: game.rules, clock: laterClock))
        #expect(resumed.isPaused)
        #expect(resumed.remainingSeconds == game.remainingSeconds)
        #expect(resumed.phoneNow == game.phoneNow)
        #expect(resumed.notebook == game.notebook)
        #expect(resumed.seen == game.seen)
        #expect(resumed.marks == game.marks)
        #expect(resumed.usedHints.map(\.id) == game.usedHints.map(\.id))
        #expect(resumed.access(to: .notes) == .open)
        #expect(resumed.visibleMessages(in: "c_emma").map(\.id) == game.visibleMessages(in: "c_emma").map(\.id))
        #expect(resumed.notifications.map(\.id) == game.notifications.map(\.id))
        #expect(resumed.drainEvents().isEmpty) // no banner replayed for what was already seen
        #expect(resumed.foundEvidence.map(\.id) == game.foundEvidence.map(\.id))

        // The timer and the phone's clock go on together, then the case ends normally.
        resumed.resume()
        for _ in 0..<30 { laterClock.advance(by: 1); resumed.tick() }
        #expect(resumed.remainingSeconds == game.remainingSeconds - 30)
        #expect(resumed.phoneNow == game.phoneNow.adding(seconds: 30))
        let verdict = try #require(resumed.accuse("s_emma"))
        #expect(verdict.isCorrect && verdict.foundCount == 2)
        #expect(resumed.snapshot() == nil) // a finished case is not resumable
    }

    @Test func aSnapshotOfAnotherCaseIsRefused() throws {
        let (game, _) = Fixtures.investigation()
        game.start()
        var saved = try #require(game.snapshot())
        saved.caseID = "case_999"
        #expect(Investigation(restoring: saved, caseFile: game.caseFile, rules: game.rules, clock: ManualClock()) == nil)
    }
}
