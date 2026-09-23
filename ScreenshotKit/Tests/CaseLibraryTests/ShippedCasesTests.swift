import Foundation
import Testing
import CaseEngine
import CaseLibrary

/// Guards the real JSON shipped with the game. Edit a case, run `swift test`: these tests say what is wrong.
@Suite("Shipped cases")
struct ShippedCasesTests {
    @Test func rulesLoad() throws {
        let rules = try CaseLibrary.loadRules()
        #expect(rules.timeCosts.analyzePhoto > rules.timeCosts.openPhoto)
        #expect(rules.messagesPageSize > 0)
    }

    @Test func everyCaseIsValid() throws {
        let cases = try CaseLibrary.loadCases()
        #expect(!cases.isEmpty)
        for file in cases {
            let issues = CaseValidator.validate(file)
            #expect(issues.isEmpty, "\(issues.map(\.description).joined(separator: "\n"))")
        }
        #expect(Set(cases.map(\.number)).count == cases.count, "two cases share a number")
    }

    @Test func everyCaseIsSolvableInTime() throws {
        let rules = try CaseLibrary.loadRules()
        for file in try CaseLibrary.loadCases() {
            let report = CaseAnalysis.analyze(file, rules: rules)
            #expect(report.isComfortablySolvable, "\(file.id): \(report.estimatedSolveSeconds) s for \(report.duration) s")
            // The phone must be a real haystack: most messages are not evidence.
            #expect(report.noiseRatio > 0.7, "\(file.id): only \(Int(report.noiseRatio * 100)) % noise")
        }
    }

    @Test func firstCaseMatchesTheDesign() throws {
        let file = try #require(try CaseLibrary.loadCases().first { $0.id == "case_001" })
        #expect(file.title == "LE DERNIER MESSAGE")
        #expect(file.durationSeconds == 480)
        #expect(Set(file.suspects.map { $0.contact }) == ["sarah", "karim", "lucas", "emma"])
        let device = try #require(file.devices.first)
        #expect(device.conversations.flatMap(\.messages).count >= 150)
        #expect(device.photos.count >= 30)
        #expect(!device.calls.isEmpty && !device.tracks.isEmpty && !device.calendar.isEmpty)
        #expect(!device.notes.isEmpty && !device.browser.isEmpty && !device.mails.isEmpty)
        #expect(device.liveEvents.count >= 6)
        #expect(device.conversations.flatMap(\.messages).contains { $0.deletedAt != nil })
        #expect(file.evidence.contains { $0.importance == .falseLead })
    }
}

/// Plays case #001 end to end through the engine, like a player would.
@Suite("Case #001 playthrough")
struct PlaythroughTests {
    private func newGame() throws -> (Investigation, ManualClock) {
        let file = try #require(try CaseLibrary.loadCases().first { $0.id == "case_001" })
        let clock = ManualClock(start: Date(timeIntervalSince1970: 1_000_000))
        return (Investigation(caseFile: file, rules: try CaseLibrary.loadRules(), clock: clock), clock)
    }

    private func wait(_ seconds: Int, _ game: Investigation, _ clock: ManualClock) -> [InvestigationEvent] {
        var events: [InvestigationEvent] = []
        for _ in 0..<(seconds * 4) { clock.advance(by: 0.25); game.tick(); events += game.drainEvents() }
        return events
    }

    @Test func aCarefulPlayerSolvesIt() throws {
        let (game, clock) = try newGame()
        game.start()
        #expect(game.remainingSeconds == 480)

        // The phone keeps living: Lucas writes 25 s in.
        let early = wait(26, game, clock)
        #expect(early.contains { if case .notification(let n) = $0 { n.title == "Lucas Ferrand" } else { false } })

        // Messages: Emma's alibi message is on the first page of her conversation.
        game.openApp(.messages)
        game.openConversation("c_emma")
        let emmaPage = game.loadedMessages(in: "c_emma")
        let alibi = try #require(emmaPage.first { $0.id == "m_emma_2230" })
        #expect(alibi.message.photo == "p_emma_couch")
        emmaPage.forEach { game.markSeen(ItemRef(.message, $0.id)) }

        // Searching "22h" finds messages around the rendez-vous time.
        let hits = game.search("22h")
        #expect(hits.contains { $0.id == "m_emma_2230" })
        #expect(!game.search("Quai 9").contains { $0.id == "m_emma_del1" }) // still deleted

        // Scrolling back in Sarah's conversation finds the unsent draft.
        game.openConversation("c_sarah")
        game.markSeen(ItemRef(.draft, "d_sarah"))

        // Trash: the rendez-vous.
        game.openApp(.trash)
        #expect(game.trash.map(\.id).contains("m_emma_del1"))
        game.recoverMessage("m_emma_del1")
        #expect(game.visibleMessages(in: "c_emma").contains { $0.id == "m_emma_del1" && $0.state == .recovered })

        // Photos: the "home" photo was taken at 19:42, not 22:30.
        game.openApp(.photos)
        let couch = try #require(game.photos.first { $0.id == "p_emma_couch" })
        #expect(couch.takenAt.clockText == "19:42" && couch.receivedAt?.clockText == "22:30")
        game.openPhoto("p_emma_couch")
        game.analyzePhoto("p_emma_couch")

        // Location: Emma stopped sharing; Lucas drove via her street to the port.
        game.openApp(.location)
        game.openTrack("t_emma")
        game.openTrack("t_lucas")
        let lucas = try #require(game.index.track("t_lucas"))
        #expect(lucas.points.contains { $0.place == "pl_home_emma" && $0.at.clockText == "21:58" })

        // Calendar, then the locked notes (code = birthday found in Contacts / Mom's messages).
        game.openApp(.calendar)
        game.openCalendarEvent("c_quai9")
        #expect(game.openApp(.notes) == .locked)
        #expect(game.unlock(.notes, code: "1609"))
        game.openApp(.notes)
        game.openNote("n_lumen")

        // Emma deletes her group alibi message during the investigation.
        _ = wait(300, game, clock)
        let tombstone = game.visibleMessages(in: "c_group").first { $0.id == "m_group_emma_2234" }
        #expect(tombstone?.state == .removedBySender)
        #expect(game.notifications.count >= 6)
        #expect(game.phase == .investigating && game.remainingSeconds > 0)

        let verdict = try #require(game.accuse("s_emma"))
        #expect(verdict.isCorrect)
        #expect(!verdict.missed.contains { $0.importance == .key }, "missed: \(verdict.missed.map(\.id))")
        #expect(verdict.score >= 75)
    }

    @Test func runningOutOfTimeThenAccusingTheWrongPerson() throws {
        let (game, clock) = try newGame()
        game.start()
        game.openApp(.location)
        game.openTrack("t_lucas") // sees Lucas at the port at 22:17…
        game.openApp(.messages)
        game.openConversation("c_group")
        game.markSeen(ItemRef(.message, "m_group_lucas_2340")) // …and his lie in the group.
        game.link(ItemRef(.message, "m_group_lucas_2340"), to: "s_lucas")

        let events = wait(480, game, clock)
        #expect(events.contains(.timeUp))
        #expect(game.phase == .accusing && game.remainingSeconds == 0)

        let verdict = try #require(game.accuse("s_lucas"))
        #expect(!verdict.isCorrect)
        #expect(verdict.accusedText.contains("rocade"))
        // What they got right about Lucas is acknowledged…
        #expect(Set(verdict.foundAboutAccused.map(\.id)).isSuperset(of: ["e_lucas_route", "f_lucas_lie"]))
        // …and what they missed is listed, to make them want to replay.
        #expect(verdict.missed.contains { $0.id == "e_photo_meta" })
        #expect(verdict.alibi?.contains("rocade") == true && verdict.trap != nil)
        #expect((verdict.missedByApp[.photos] ?? 0) >= 1 && (verdict.missedByApp[.trash] ?? 0) >= 1)
        #expect(verdict.score < 40)
    }
}
