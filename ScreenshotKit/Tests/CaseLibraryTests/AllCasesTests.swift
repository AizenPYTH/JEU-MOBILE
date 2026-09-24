import Foundation
import Testing
import CaseEngine
import CaseLibrary

/// Every shipped case, played through the engine: solvable at the hardest level by crossing
/// several apps, each innocent cleared by their alibi, and each case its own story.
@Suite("All cases")
struct AllCasesTests {
    private static func cases() throws -> [CaseFile] { try CaseLibrary.loadCases() }

    /// The app an item is found in.
    private static func app(of ref: ItemRef, in file: CaseFile) -> AppID? {
        switch ref.kind {
        case .message:
            let message = file.devices.flatMap(\.conversations).flatMap(\.messages).first { $0.id == ref.id }
            return message?.deletedAt != nil ? .trash : .messages
        case .draft: return .messages
        case .call: return .phone
        case .photo, .photoInfo: return .photos
        case .track: return .location
        case .calendar: return .calendar
        case .note: return .notes
        case .mail: return .mail
        case .browser: return .browser
        case .contact: return .contacts
        case .app: return AppID(rawValue: ref.id)
        }
    }

    /// Does what a player would do to see an item (opening, scrolling back, recovering, unlocking).
    private static func reach(_ ref: ItemRef, in game: Investigation) {
        switch ref.kind {
        case .message:
            if let message = game.index.message(ref.id), message.deletedAt != nil {
                game.openApp(.trash)
                game.recoverMessage(ref.id)
                return
            }
            game.openApp(.messages)
            if let conversation = game.index.conversationID(ofMessage: ref.id) {
                game.openConversation(conversation)
                while !game.loadedMessages(in: conversation).contains(where: { $0.id == ref.id }) && game.hasOlderMessages(in: conversation) {
                    game.loadOlderMessages(in: conversation)
                }
            }
            game.markSeen(ref)
        case .draft, .call:
            game.openApp(ref.kind == .call ? .phone : .messages)
            game.markSeen(ref)
        case .photo:
            game.openApp(.photos); game.openPhoto(ref.id)
        case .photoInfo:
            game.openApp(.photos); game.openPhoto(ref.id); game.analyzePhoto(ref.id)
        case .track:
            game.openApp(.location); game.openTrack(ref.id)
        case .calendar:
            game.openApp(.calendar); game.openCalendarEvent(ref.id)
        case .note:
            if game.openApp(.notes) == .locked, let lock = game.device.lockedApps.first(where: { $0.app == .notes }) {
                _ = game.unlock(.notes, code: lock.code)
                game.openApp(.notes)
            }
            game.openNote(ref.id)
        case .mail:
            game.openApp(.mail); game.openMail(ref.id)
        case .browser:
            game.openApp(.browser); game.openBrowserEntry(ref.id)
        case .contact:
            game.openApp(.contacts); game.openContact(ref.id)
        case .app:
            if let app = AppID(rawValue: ref.id) { game.openApp(app) }
        }
    }

    @Test func thereAreAtLeastFiveCases() throws {
        let cases = try Self.cases()
        #expect(cases.count >= 5)
        #expect(cases.map(\.number) == Array(1...cases.count), "case numbers must follow each other")
    }

    /// A careful player, at Expert (5 minutes): reaches every key item, links it to the culprit,
    /// accuses. Time costs alone must leave time to spare, and the answer must be right.
    @Test func everyCaseIsSolvedByCrossingItsKeyEvidenceAtExpert() throws {
        let rules = try CaseLibrary.loadRules()
        for original in try Self.cases() {
            let file = original.configured(for: .expert, rules: rules)
            let game = Investigation(caseFile: file, rules: rules, clock: ManualClock(), challenge: .expert)
            game.start()
            let culprit = file.solution.culprit
            for evidence in file.evidence where evidence.importance == .key {
                let refs = evidence.anyOf == true ? Array(evidence.refs.prefix(1)) : evidence.refs
                for ref in refs {
                    Self.reach(ref, in: game)
                    game.link(ref, to: culprit)
                }
                #expect(game.isFound(evidence), "\(file.id): \(evidence.id) not found after reaching \(refs)")
            }
            #expect(game.remainingSeconds > Double(file.durationSeconds) * 0.4,
                    "\(file.id): the key actions alone use \(Int(game.elapsedSeconds)) s of \(file.durationSeconds) s")
            let verdict = try #require(game.accuse(culprit))
            #expect(verdict.isCorrect, "\(file.id)")
            #expect(!verdict.missed.contains { $0.importance == .key }, "\(file.id): missed \(verdict.missed.map(\.id))")
            #expect(verdict.score >= 70, "\(file.id): score \(verdict.score)")
        }
    }

    /// The truth is never in one app: the key evidence spans at least three apps.
    @Test func theTruthAlwaysCrossesSeveralApps() throws {
        for file in try Self.cases() {
            let apps = Set(file.evidence.filter { $0.importance == .key }.flatMap(\.refs).compactMap { Self.app(of: $0, in: file) })
            #expect(apps.count >= 3, "\(file.id): key evidence only in \(apps.map(\.rawValue).sorted())")
            let aboutCulprit = file.evidence.filter { $0.importance == .key && $0.suspects.contains(file.solution.culprit) }
            #expect(aboutCulprit.count >= 3, "\(file.id): only \(aboutCulprit.count) key pieces against the culprit")
        }
    }

    /// Every innocent looks guilty for a reason (a trap, a false lead) and is cleared by evidence.
    @Test func everyInnocentHasATrapAndAnAlibi() throws {
        let rules = try CaseLibrary.loadRules()
        for file in try Self.cases() {
            for suspect in file.suspects where suspect.id != file.solution.culprit {
                #expect(suspect.trap != nil, "\(file.id): \(suspect.id) has no trap")
                let alibi = try #require(file.evidence.first { $0.id == suspect.alibiEvidence }, "\(file.id): \(suspect.id) alibi evidence")
                #expect(alibi.suspects.contains(suspect.id), "\(file.id): \(alibi.id) should be about \(suspect.id)")
                #expect(file.evidence.contains { $0.importance == .falseLead && $0.suspects.contains(suspect.id) }
                        || file.evidence.contains { $0.importance == .key && $0.suspects.contains(suspect.id) },
                        "\(file.id): nothing points at \(suspect.id) — why would anyone suspect them?")
                // Accusing them is wrong, and the result explains why.
                let game = Investigation(caseFile: file, rules: rules, clock: ManualClock())
                game.start()
                let verdict = try #require(game.accuse(suspect.id))
                #expect(!verdict.isCorrect)
                #expect(verdict.alibi != nil && verdict.trap != nil, "\(file.id): \(suspect.id)")
            }
            #expect(file.suspects.count >= 4, "\(file.id): at least 4 suspects")
        }
    }

    /// Live events (which only happen if the player has time) never hold the proof.
    @Test func keyEvidenceIsInThePhoneFromTheStart() throws {
        for file in try Self.cases() {
            let live = Set(file.devices.flatMap(\.liveEvents).compactMap { $0.message?.id } + file.devices.flatMap(\.liveEvents).compactMap { $0.call?.id })
            for evidence in file.evidence where evidence.importance == .key {
                let reachable = evidence.refs.filter { !live.contains($0.id) }
                #expect(evidence.anyOf == true ? !reachable.isEmpty : reachable.count == evidence.refs.count,
                        "\(file.id): \(evidence.id) depends on a live event")
            }
        }
    }

    /// Same levels everywhere, three hints in tiers (free clue, place, evidence).
    @Test func levelsAndHintsFollowTheRules() throws {
        let rules = try CaseLibrary.loadRules()
        for file in try Self.cases() {
            #expect(file.duration(for: .investigator, rules: rules) == 900, "\(file.id)")
            #expect(file.duration(for: .detective, rules: rules) == 480, "\(file.id)")
            #expect(file.duration(for: .expert, rules: rules) == 300, "\(file.id)")
            #expect(file.hints.map(\.scoreCost) == [0, 8, 15], "\(file.id): hints \(file.hints.map(\.scoreCost))")
            #expect(file.hints.last?.unlockAtRemainingSeconds != nil, "\(file.id): the last hint unlocks late")
        }
    }

    /// Each case is its own story: its own people, places, phone and opening.
    @Test func casesAreDistinct() throws {
        let cases = try Self.cases()
        #expect(Set(cases.map(\.title)).count == cases.count)
        // Family words are allowed in every phone ("Maman", "Papa"); real names are not shared.
        let family: Set<String> = ["Maman", "Papa", "Mamie", "Papi"]
        var owners: [String: String] = [:]
        for file in cases {
            for contact in file.devices.flatMap(\.contacts) where !family.contains(contact.name) {
                if let other = owners[contact.name], other != file.id {
                    Issue.record("\(contact.name) appears in \(other) and \(file.id)")
                }
                owners[contact.name] = file.id
            }
        }
        var places: [String: String] = [:]
        for file in cases {
            for place in file.devices.flatMap(\.places) {
                if let other = places[place.name], other != file.id { Issue.record("place « \(place.name) » in \(other) and \(file.id)") }
                places[place.name] = file.id
            }
        }
        // Different openings: no two cases start on the same picture, and each ends on the phone.
        var firstScenes: [String] = []
        for file in cases {
            let intro = try #require(file.introScene, "\(file.id) has no opening")
            #expect(intro.shots.last?.kind == .unlock, "\(file.id): the opening ends on the phone")
            #expect(intro.shots.contains { $0.kind == .phoneOnTable }, "\(file.id): the phone is shown where it lies")
            let first = intro.shots.first { $0.scene != nil }?.scene ?? intro.shots.first?.kind.rawValue ?? ""
            #expect(!firstScenes.contains(first), "\(file.id): same first picture as another case (\(first))")
            firstScenes.append(first)
        }
        // Different phones: owner, wallpaper, model or battery.
        let looks = cases.map { file -> String in
            let d = file.devices[0]
            return "\(d.wallpaper?.rawValue ?? "night")-\(d.batteryPercent ?? 23)"
        }
        #expect(Set(looks).count == cases.count, "two phones look the same: \(looks)")
    }
}
