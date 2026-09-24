import Foundation
import Testing
@testable import CaseEngine

@Suite("Challenge levels")
struct ChallengeTests {
    @Test func levelsChangeOnlyTheDuration() {
        var file = Fixtures.caseFile
        file.challengeDurations = ["investigator": 900, "expert": 180]
        let rules = Fixtures.rules
        #expect(file.duration(for: .investigator, rules: rules) == 900)
        #expect(file.duration(for: .detective, rules: rules) == 300) // default factor 1
        #expect(file.duration(for: .expert, rules: rules) == 180)
        let expert = file.configured(for: .expert, rules: rules)
        #expect(expert.durationSeconds == 180)
        #expect(expert.evidence == file.evidence && expert.suspects == file.suspects) // same story
    }

    @Test func defaultFactorsRoundToHalfMinutes() {
        let file = Fixtures.caseFile // 300 s, no own durations
        #expect(file.duration(for: .investigator, rules: Fixtures.rules) == 570) // 300 × 1.875 = 562.5 → 570
        #expect(file.duration(for: .expert, rules: Fixtures.rules) == 180)       // 300 × 0.625 = 187.5 → 180
    }

    @Test func expertUnlocksOnceSolvedAtDetectiveOrHarder() {
        let rules = Fixtures.rules
        #expect(rules.isUnlocked(.investigator, solvedAt: []))
        #expect(rules.isUnlocked(.detective, solvedAt: []))
        #expect(!rules.isUnlocked(.expert, solvedAt: []))
        #expect(!rules.isUnlocked(.expert, solvedAt: [.investigator]))
        #expect(rules.isUnlocked(.expert, solvedAt: [.detective]))
        #expect(rules.isUnlocked(.expert, solvedAt: [.expert]))
    }

    @Test func thePlayRemembersItsLevelAcrossASaveAndTheTimerUsesItsDuration() throws {
        let rules = Fixtures.rules
        let file = Fixtures.caseFile.configured(for: .expert, rules: rules)
        let clock = ManualClock(start: Date(timeIntervalSince1970: 1_000_000))
        let game = Investigation(caseFile: file, rules: rules, clock: clock, challenge: .expert)
        game.start()
        for _ in 0..<10 { clock.advance(by: 1); game.tick() } // real time runs one tick at a time
        #expect(game.remainingSeconds == 170)
        let snapshot = try #require(game.snapshot())
        #expect(snapshot.challenge == .expert && snapshot.durationSeconds == 180)
        let restored = try #require(Investigation(restoring: snapshot, caseFile: Fixtures.caseFile, rules: rules, clock: clock))
        #expect(restored.challenge == .expert && restored.durationSeconds == 180 && restored.remainingSeconds == 170)
    }

    @Test func gamesSavedBeforeLevelsResumeAsDetective() throws {
        let (game, clock) = Fixtures.investigation()
        game.start()
        var snapshot = try #require(game.snapshot())
        snapshot.challenge = nil
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(InvestigationSnapshot.self, from: data)
        let restored = try #require(Investigation(restoring: decoded, caseFile: Fixtures.caseFile, rules: Fixtures.rules, clock: clock))
        #expect(restored.challenge == .detective)
    }
}

@Suite("Places on the map")
struct PlacesTests {
    static func file(revealedBy: [ItemRef]?) -> CaseFile {
        var file = Fixtures.caseFile
        file.devices[0].places.append(Place(id: "pl2", name: "Rocade", kind: .road, x: 0.5, y: 0.5,
                                            latitude: 43.3, longitude: 5.4, revealedBy: revealedBy))
        file.devices[0].tracks[0].points.append(TrackPoint(id: "tp2", at: Fixtures.m("2026-09-12 20:00"), place: "pl2", note: nil))
        return file
    }

    @Test func aHiddenPlaceAppearsOnceItsClueIsSeen() {
        let game = Investigation(caseFile: Self.file(revealedBy: [ItemRef(.calendar, "cal1")]), rules: Fixtures.rules, clock: ManualClock())
        game.start()
        #expect(game.knownPlaces.map(\.id) == ["pl1"])
        game.openCalendarEvent("cal1")
        #expect(game.knownPlaces.map(\.id) == ["pl1", "pl2"])
    }

    @Test func aHiddenPlaceAppearsOnceARouteThroughItIsOpened() {
        let game = Investigation(caseFile: Self.file(revealedBy: [ItemRef(.calendar, "cal1")]), rules: Fixtures.rules, clock: ManualClock())
        game.start()
        game.openTrack("t_emma")
        #expect(game.knownPlaces.contains { $0.id == "pl2" })
    }

    @Test func coordinatesAndCluesAreValidated() {
        var file = Self.file(revealedBy: [ItemRef(.note, "nope")])
        file.devices[0].places[0].latitude = 43
        let issues = CaseValidator.validate(file).map(\.message)
        #expect(issues.contains { $0.contains("revealed by unknown") })
        #expect(issues.contains { $0.contains("both latitude and longitude") })
    }
}

@Suite("Intro scene")
struct IntroSceneTests {
    @Test func shotsAreValidatedAndDecoded() throws {
        let json = #"""
        {"shots":[{"kind":"title","seconds":3,"ambience":["sirens"],"lines":[{"text":"Dimanche","at":0.5}]},
                  {"kind":"broadcast","seconds":10,"channel":"INFO 24","lines":[{"text":"Nous sommes…","at":1,"voiced":true}]},
                  {"kind":"phoneOnTable","seconds":4,"notification":{"app":"messages","title":"Maman","body":"Rappelle-moi","at":1.5},
                   "cues":[{"sound":"vibrate","at":1.5}]},
                  {"kind":"unlock","seconds":2}]}
        """#
        let scene = try JSONDecoder().decode(IntroScene.self, from: Data(json.utf8))
        #expect(scene.shots.count == 4 && scene.totalSeconds == 19)
        var file = Fixtures.caseFile
        file.introScene = scene
        #expect(CaseValidator.validate(file).isEmpty)
        file.introScene?.shots[2].notification?.at = 9
        #expect(CaseValidator.validate(file).contains { $0.message.contains("notification is outside") })
    }
}
