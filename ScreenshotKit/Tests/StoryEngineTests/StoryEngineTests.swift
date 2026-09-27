import Foundation
import Testing
@testable import StoryEngine

/// A tiny hand-made story so the engine is tested without the shipped content.
enum StoryFixture {
    static let appearance = CharacterAppearance(presentation: "presentation_f", skinTone: "skin_01", face: "face_01", hairStyle: "hair_01",
                                                hairColor: "haircolor_01", beard: "beard_none", eyeColor: "eyes_01",
                                                outfit: "outfit_01a")

    static var catalog: CharacterCatalog {
        func v(_ id: String, _ slot: AppearanceSlot, unlock: String? = nil, presentations: [String]? = nil, npcOnly: Bool? = nil) -> CharacterVariant {
            CharacterVariant(id: id, slot: slot, label: id, labelEn: nil, color: "#112233", accent: nil, shape: nil, group: nil,
                             presentations: presentations, unlock: unlock, npcOnly: npcOnly)
        }
        return CharacterCatalog(variants: [
            v("presentation_f", .presentation), v("presentation_m", .presentation),
            v("skin_01", .skinTone), v("face_01", .face), v("hair_01", .hairStyle), v("hair_02", .hairStyle), v("haircolor_01", .hairColor),
            v("beard_none", .beard), v("beard_01", .beard, presentations: ["presentation_m"]),
            v("eyes_01", .eyeColor), v("outfit_01a", .outfit), v("outfit_01b", .outfit),
            v("outfit_boss", .outfit, npcOnly: true),
        ], defaultAppearance: appearance)
    }

    static var location: StoryLocation {
        StoryLocation(id: "ROOM", name: "Room", size: [4, 4, 3], wallColor: "#333333", floorColor: "#222222", accentColor: nil,
                      lighting: "office_day", ambience: "room",
                      anchors: [StageAnchor(id: "door", x: 1.5, z: 1.5, facing: 270, seated: nil),
                                StageAnchor(id: "desk", x: 0, z: -1, facing: 0, seated: true),
                                StageAnchor(id: "visitor", x: 0, z: 0.5, facing: 180, seated: nil)],
                      cameras: [CameraAnchor(id: "cam_wide", x: 1.5, y: 1.7, z: 1.9, lookX: 0, lookY: 1, lookZ: -1, focal: 28, fov: nil),
                                CameraAnchor(id: "cam_ms", x: 0.3, y: 1.3, z: 0.4, lookX: 0, lookY: 1.2, lookZ: -1, focal: 50, fov: nil),
                                CameraAnchor(id: "cam_cu", x: 0.2, y: 1.2, z: -0.2, lookX: 0, lookY: 1.2, lookZ: -1, focal: 85, fov: nil),
                                CameraAnchor(id: "cam_top", x: 0.2, y: 1.2, z: -0.2, lookX: 0, lookY: 0.8, lookZ: -0.6, focal: 100, fov: nil)],
                      props: [StageProp(id: "file", kind: "folder", x: 0, z: -0.6, y: 0.76, hidden: true),
                              StageProp(id: "card", kind: "card", x: 0.3, z: -0.6, y: 0.76, requires: "office_card", label: "{player.LASTNAME}",
                                        hotspot: PropHotspot(label: "CARTE", name: "Carte BEN", provenance: nil, camera: "cam_top")),
                              StageProp(id: "safe", kind: "safe", x: -1.5, z: 0, level: 4),
                              StageProp(id: "metal_desk", kind: "desk", x: 0, z: -1, maxLevel: 2)])
    }

    static func beat(_ kind: SceneBeat.Kind, _ configure: (inout SceneBeat) -> Void = { _ in }) -> SceneBeat {
        var b = SceneBeat(kind: kind)
        configure(&b)
        return b
    }

    static var sceneA: StoryScene {
        StoryScene(id: "scene_a", title: nil, location: "ROOM", place: "BEN · BUREAU 312 · 21:04", participants: ["player", "boss"], beats: [
            beat(.place) { $0.actor = "boss"; $0.anchor = "desk" },
            beat(.camera) { $0.shot = CameraShot(kind: .wide, camera: "cam_wide") },
            beat(.title) { $0.text = "CHAPITRE 1"; $0.seconds = 2 },
            beat(.enter) { $0.actor = "player"; $0.anchor = "visitor"; $0.from = "door" },
            beat(.camera) { $0.shot = CameraShot(kind: .medium, camera: "cam_ms", subject: "boss") },
            beat(.dialogue) { $0.node = "l1" },
            beat(.animate) { $0.actor = "boss"; $0.animation = "handover" },
            beat(.show) { $0.target = "file" },
            beat(.wait) { $0.seconds = 2; $0.silence = true },
            beat(.camera) { $0.shot = CameraShot(kind: .focusObject, camera: "cam_top", prop: "file") },
            beat(.notification) { $0.title = "Nouveau message"; $0.text = "Numéro inconnu" },
        ], dialogue: [
            DialogueNode(id: "l1", speaker: "boss", text: "Bonjour {player.lastName}. Vous êtes {g:attendu|attendue}.", next: "l2"),
            DialogueNode(id: "l2", speaker: "boss", text: "Prête ?", choices: [
                DialogueChoice(id: "yes", text: "Oui.", kind: .relational, remember: "Vous avez dit oui.",
                               effects: [StoryEffect(kind: .trust, npc: "boss", amount: 2)], next: "l3"),
                DialogueChoice(id: "wait", text: "Pas encore.", kind: .narrative, effects: [StoryEffect(kind: .flag, flag: "hesitated")], next: "l4"),
                DialogueChoice(id: "silence", text: "Ne rien dire", kind: .narrative, silent: true,
                               remember: "Vous n'avez rien dit.",
                               shot: CameraShot(kind: .closeUp, camera: "cam_cu", subject: "boss"), pause: 2,
                               effects: [StoryEffect(kind: .flag, flag: "silent")], next: "l5"),
            ]),
            DialogueNode(id: "l3", speaker: "boss", text: "Bien.", next: nil),
            DialogueNode(id: "l4", speaker: "boss", text: "Prenez votre temps.", next: nil),
            DialogueNode(id: "l5", speaker: "boss", text: "Je vois.", next: nil),
        ])
    }

    static var sceneB: StoryScene {
        StoryScene(id: "scene_b", title: nil, location: "ROOM", participants: ["player", "boss"], beats: [
            beat(.place) { $0.actor = "player"; $0.anchor = "visitor" },
            beat(.camera) { $0.shot = CameraShot(kind: .wide, camera: "cam_wide") },
            beat(.wait) { $0.seconds = 3 },
            beat(.dialogue) { $0.node = "ok"; $0.condition = StoryCondition(lastCaseSolved: true) },
            beat(.dialogue) { $0.node = "ko"; $0.condition = StoryCondition(lastCaseSolved: false) },
        ], dialogue: [
            DialogueNode(id: "ok", speaker: "boss", text: "Bien joué.", next: nil),
            DialogueNode(id: "ko", speaker: "boss", text: "On en reparlera.", next: nil),
        ])
    }

    static var campaign: StoryCampaign {
        StoryCampaign(chapters: [
            StoryChapter(id: "chapter_01", number: 1, title: "Première affectation", synopsis: "…", status: .playable, steps: [
                ChapterStep(id: "s1", kind: .scene, scene: "scene_a"),
                ChapterStep(id: "s2", kind: .investigation, caseID: "story_001"),
                ChapterStep(id: "s3", kind: .scene, scene: "scene_b"),
                ChapterStep(id: "s4", kind: .result, reward: StoryReward(items: [RewardItem(id: "office_card", name: "Carte BEN", provenance: nil)],
                                                                          unlocks: ["office_01"])),
                ChapterStep(id: "s5", kind: .office),
            ], summary: "Résolu.", summaryUnsolved: "Classé.", note: "À suivre."),
            StoryChapter(id: "chapter_02", number: 2, title: "Suite", synopsis: "…", status: .planned, steps: []),
        ], career: [CareerTier(rank: .enqueteur, cases: 0, chapter: nil), CareerTier(rank: .inspecteur, cases: 1, chapter: 1),
                    CareerTier(rank: .senior, cases: 20, chapter: 4), CareerTier(rank: .experimente, cases: 30, chapter: 7)],
                      monthsPerChapter: 3)
    }

    static var content: StoryContent {
        StoryContent(
            catalog: catalog,
            npcs: [StoryNPC(id: "boss", firstName: "Bernard", lastName: "Lacaze", title: "Cdt.", role: "Commandant", appearance: StoryFixture.npcLook, bio: nil)],
            locations: [location],
            campaign: campaign,
            scenes: [sceneA, sceneB])
    }

    static let npcLook = CharacterAppearance(presentation: "presentation_m", skinTone: "skin_01", face: "face_01", hairStyle: "hair_02",
                                             hairColor: "haircolor_01", beard: "beard_01", eyeColor: "eyes_01", outfit: "outfit_boss")

    static var player: StoryPlayer { StoryPlayer(firstName: "Camille", lastName: "Arnaud", appearance: appearance) }

    static func director(_ save: StorySave? = nil) -> StoryDirector {
        StoryDirector(content: content, save: save ?? StorySave(player: player, firstChapter: "chapter_01"))
    }

    /// Plays chapter 1 up to the phone, answering `choice`.
    static func toThePhone(_ d: StoryDirector, choice: String = "yes") {
        d.resume(); d.advance(); d.advance()
        d.choose(choice)
        d.fastForward()
        if d.stage.notification != nil { d.advance() }
    }
}

@Suite("Story — character")
struct CharacterTests {
    @Test func creatorOptionsFollowTheBase() {
        let catalog = StoryFixture.catalog
        #expect(catalog.options(for: .beard, presentation: "presentation_f", unlocked: []).map(\.id) == ["beard_none"])
        #expect(catalog.options(for: .beard, presentation: "presentation_m", unlocked: []).map(\.id) == ["beard_none", "beard_01"])
        // The BEN's own clothes are never offered to the player.
        #expect(!catalog.options(for: .outfit, presentation: "presentation_m", unlocked: []).contains { $0.id == "outfit_boss" })
    }

    @Test func appearanceIsFittedToItsBase() {
        let catalog = StoryFixture.catalog
        var look = StoryFixture.appearance
        look.presentation = "presentation_m"
        look.beard = "beard_01"
        #expect(catalog.isValid(look, unlocked: []))
        look.presentation = "presentation_f"
        #expect(!catalog.isValid(look, unlocked: []))
        let fitted = catalog.fitted(look, unlocked: [])
        #expect(fitted.beard == "beard_none")
        #expect(catalog.isValid(fitted, unlocked: []))
    }

    @Test func namesFollowTheRulesOfAnOfficialFile() {
        #expect(StoryPlayer.isValidName("Anne-Sophie"))
        #expect(StoryPlayer.isValidName("D'Arcy"))
        #expect(StoryPlayer.isValidName("Éloïse"))
        #expect(!StoryPlayer.isValidName("A"))
        #expect(!StoryPlayer.isValidName("R2-D2"))
        #expect(!StoryPlayer.isValidName(String(repeating: "a", count: 21)))
        #expect(StoryPlayer.normalized("  jean-marc   d'arcy ") == "Jean-Marc D'Arcy")
        let reserved = ["Bernard Lacaze"]
        #expect(StoryPlayer.nameProblem(firstName: "Camille", lastName: "Arnaud", reserved: reserved) == nil)
        #expect(StoryPlayer.nameProblem(firstName: "bernard", lastName: "lacaze", reserved: reserved) == .reserved)
        #expect(StoryPlayer.nameProblem(firstName: "Jean", lastName: "Merde", reserved: reserved) == .offensive)
        // Whole words only.
        #expect(StoryPlayer.nameProblem(firstName: "Cassandre", lastName: "Bitcher", reserved: reserved) == nil)
        #expect(StoryPlayer.nameProblem(firstName: "X", lastName: "Arnaud", reserved: reserved) == .format)
    }

    @Test func serviceNumbersAreStable() {
        let a = StoryPlayer(firstName: "Camille", lastName: "Arnaud", appearance: StoryFixture.appearance)
        let b = StoryPlayer(firstName: "Camille", lastName: "Arnaud", appearance: StoryFixture.npcLook)
        #expect(a.serviceNumber == b.serviceNumber)
        #expect(a.serviceNumber.hasPrefix("BEN-0") && a.serviceNumber.count == 9)
        let seeded = StoryPlayer(firstName: "Camille", lastName: "Arnaud", appearance: StoryFixture.appearance,
                                 serviceNumber: StoryPlayer.serviceNumber(for: "Camille Arnaud 2026-09-27T10:00"))
        #expect(seeded.serviceNumber.hasPrefix("BEN-0"))
    }

    @Test func textSpeaksToThePlayer() {
        let f = StoryFixture.player
        #expect(f.agreement == .feminine)
        #expect(StoryText.resolve("{player.LASTNAME}, vous êtes {g:attendu|attendue}.", player: f, rank: .enqueteur) == "ARNAUD, vous êtes attendue.")
        var m = f
        m.agreement = .masculine
        #expect(StoryText.resolve("{g:attendu|attendue}", player: m, rank: .inspecteur) == "attendu")
        var n = f
        n.agreement = .neutral
        #expect(StoryText.resolve("{g:attendu|attendue|attendu·e}", player: n, rank: .enqueteur) == "attendu·e")
        #expect(StoryText.resolve("{player.rank}", player: n, rank: .enqueteur) == "Agent")
        #expect(StoryText.resolve("{player.rank} {player.firstName}", player: f, rank: .inspecteur) == "Inspectrice Camille")
    }

    @Test func focalsGiveThePortraitFrame() {
        let cam = CameraAnchor(id: "cam", x: 0, y: 1, z: 0, lookX: 0, lookY: 1, lookZ: -1, focal: 50, fov: nil)
        #expect(abs(cam.verticalFOV - 39.6) < 0.1)
    }
}

@Suite("Story — director")
struct DirectorTests {
    @Test func aSceneIsPlayedBeatByBeat() {
        let d = StoryFixture.director()
        let first = d.resume()
        #expect(first.contains(.sceneStarted(scene: "scene_a", location: "ROOM")))
        #expect(d.stage.titleCard == "CHAPITRE 1")
        #expect(d.autoAdvance == 2)
        #expect(d.stage.actors["boss"]?.seated == true)
        #expect(d.stage.shot?.camera == "cam_wide")
        let events = d.advance()
        #expect(events.contains(.actorEntered("player")))
        #expect(d.stage.shot?.kind == .medium)
        #expect(d.stage.line?.text == "Bonjour Arnaud. Vous êtes attendue.")
        #expect(d.stage.line?.speakerName == "Bernard Lacaze")
        #expect(d.stage.line?.speakerRole == "Commandant")
        d.advance()
        #expect(d.stage.line?.choices.map(\.id) == ["yes", "wait", "silence"])
        #expect(d.stage.line?.choices.last?.silent == true)
        // A choice is required: continuing does nothing.
        #expect(d.advance().isEmpty)
        d.choose("yes")
        #expect(d.save.relationship("boss").trust == 2)
        #expect(d.stage.line?.nodeID == "l3")
        d.advance() // end of the dialogue: the file comes out, a silent shot
        #expect(d.stage.actors["boss"]?.pose == "handover")
        #expect(d.stage.shownProps.contains("file"))
        #expect(d.autoAdvance == 2)
        d.advance()
        #expect(d.stage.shot?.kind == .focusObject)
        #expect(d.stage.notification?.title == "Nouveau message")
        let toPhone = d.advance()
        #expect(toPhone.contains(.sceneEnded("scene_a")))
        #expect(toPhone.contains(.startCase("story_001")))
        #expect(d.mode == .awaitingCase("story_001"))
        #expect(d.save.seenScenes.contains("scene_a"))
    }

    @Test func choicesChangeTheToneAndAreRemembered() {
        let d = StoryFixture.director()
        d.resume(); d.advance(); d.advance()
        d.choose("wait")
        #expect(d.save.flags.contains("hesitated"))
        #expect(d.save.relationship("boss").trust == 0)
        #expect(d.stage.line?.text == "Prenez votre temps.")
        #expect(d.save.choices["scene_a#l2"] == "wait")
        #expect(d.save.decisions["chapter_01"] == nil)

        let e = StoryFixture.director()
        e.resume(); e.advance(); e.advance()
        e.choose("yes")
        #expect(e.save.decisions["chapter_01"] == ["Vous avez dit oui."])
    }

    @Test func theSilenceIsHeldThenTheSceneGoesOn() {
        let d = StoryFixture.director()
        d.resume(); d.advance(); d.advance()
        let events = d.choose("silence")
        #expect(d.stage.line == nil)
        #expect(d.stage.shot?.kind == .closeUp)
        #expect(events.contains(.wait(2)))
        #expect(d.autoAdvance == 2)
        #expect(d.save.flags.contains("silent"))
        d.advance()
        #expect(d.stage.line?.text == "Je vois.")
    }

    @Test func theResultCountsTheChapterAndTheCareer() {
        for solved in [true, false] {
            let d = StoryFixture.director()
            StoryFixture.toThePhone(d)
            #expect(d.mode == .awaitingCase("story_001"))
            d.caseFinished("story_001", solved: solved, score: solved ? 82 : 30, found: 4, total: 6, seconds: 300)
            #expect(d.save.stats.casesCompleted == 1)
            #expect(d.save.stats.casesSolved == (solved ? 1 : 0))
            #expect(d.save.stats.mistakes == (solved ? 0 : 1))
            d.advance() // the silent wide shot
            #expect(d.stage.line?.text == (solved ? "Bien joué." : "On en reparlera."))
            d.advance()
            guard case .result(let result) = d.mode else { Issue.record("expected the result"); return }
            #expect(result.solved == solved)
            #expect(result.seconds == 300)
            #expect(result.decisions == ["Vous avez dit oui."])
            #expect(d.save.completedChapters == ["chapter_01"])
            #expect(d.save.unlocks.isSuperset(of: ["office_card", "office_01", "chapter_02"]))
            // INSPECTEUR takes a solved case AND chapter 1.
            #expect(d.save.rank == (solved ? .inspecteur : .enqueteur))
            #expect(result.promotion == (solved ? StoryPromotion(from: .enqueteur, to: .inspecteur) : nil))
            #expect(result.nextTier?.rank == (solved ? .senior : .inspecteur))
            d.advance()
            #expect(d.save.promotion == nil)
            #expect(d.mode == .office)
            let end = d.advance()
            #expect(end.contains(.chapterCompleted("chapter_01")))
            #expect(d.save.stats.chaptersCompleted == 1)
        }
    }

    @Test func casesSolvedInEveryModeCountOnce() {
        let d = StoryFixture.director()
        d.externalSolved = ["case_001", "case_002"]
        #expect(d.solvedCount == 2)
        StoryFixture.toThePhone(d)
        d.caseFinished("story_001", solved: true, score: 80, found: 3, total: 3)
        #expect(d.solvedCount == 3)
        // Solved cases alone are not enough: the chapter is needed too.
        #expect(d.save.rank == .enqueteur)
        let campaign = StoryFixture.campaign
        #expect(campaign.rank(solved: 25, chapters: [1, 2, 3]) == .inspecteur)
        #expect(campaign.rank(solved: 25, chapters: [1, 2, 3, 4]) == .senior)
        #expect(campaign.rank(solved: 19, chapters: [1, 2, 3, 4]) == .inspecteur)
    }

    @Test func alibiChecksAreHandledNotSolved() {
        let d = StoryFixture.director()
        StoryFixture.toThePhone(d)
        d.caseFinished("story_001", solved: true, score: 80, found: 3, total: 3, alibi: true)
        #expect(d.solvedCount == 0)
        #expect(d.save.stats.casesCompleted == 1)
    }

    @Test func officeLevelsFollowTheRank() {
        let location = StoryFixture.location
        #expect(location.props(unlocked: [], level: 1).map(\.id) == ["file", "metal_desk"])
        #expect(location.props(unlocked: ["office_card"], level: 4).map(\.id) == ["file", "card", "safe"])
        let d = StoryFixture.director()
        #expect(d.officeLevel == 1)
    }

    @Test func aWrongCaseIDIsIgnored() {
        let d = StoryFixture.director()
        StoryFixture.toThePhone(d)
        #expect(d.caseFinished("case_001", solved: true, score: 90, found: 5, total: 5).isEmpty)
        #expect(d.mode == .awaitingCase("story_001"))
    }

    @Test func aSceneAlreadySeenCanBePassedWithItsAnswers() {
        let d = StoryFixture.director()
        d.resume()
        #expect(!d.canSkipScene)
        StoryFixture.toThePhone(d, choice: "wait")
        d.caseFinished("story_001", solved: true, score: 80, found: 3, total: 3)
        d.advance(); d.advance(); d.advance(); d.advance()
        #expect(d.mode == .chapterComplete("chapter_01"))
        // Replayed: the answers given are shown, nothing counts, back where the player was.
        let before = d.save
        #expect(d.replayChapter("chapter_01").contains(.sceneStarted(scene: "scene_a", location: "ROOM")))
        #expect(d.isReplaying)
        #expect(d.canSkipScene)
        d.advance(); d.advance()
        #expect(d.stage.line?.choices.first { $0.chosenBefore }?.id == "wait")
        d.choose("yes")
        #expect(d.save.relationship("boss").trust == 0)
        var events: [StoryEvent] = []
        for _ in 0..<50 where !events.contains(.replayEnded) {
            if d.canSkipScene { events += d.skipScene() } else { events += d.advance() }
        }
        #expect(events.contains(.replayEnded))
        #expect(!d.isReplaying)
        #expect(d.save.position == before.position)
        #expect(d.save.stats == before.stats)
        #expect(d.save.decisions == before.decisions)
    }

    @Test func deterministic() {
        func play() -> (StageState, StorySave) {
            let d = StoryFixture.director()
            d.resume(); d.advance(); d.advance(); d.choose("wait")
            return (d.stage, d.save)
        }
        let a = play(), b = play()
        #expect(a.0 == b.0)
        #expect(a.1 == b.1)
    }

    @Test func plannedChaptersCannotStart() {
        let d = StoryFixture.director()
        #expect(d.startChapter("chapter_02").isEmpty)
    }

    @Test func theAppearanceCanChangeButNotTheBase() {
        let d = StoryFixture.director()
        var look = d.save.player.appearance
        look.presentation = "presentation_m"
        look.outfit = "outfit_01b"
        d.updateAppearance(look)
        #expect(d.save.player.appearance.presentation == "presentation_f")
        #expect(d.save.player.appearance.outfit == "outfit_01b")
    }
}

@Suite("Story — save")
struct StorySaveTests {
    /// Quit in the middle of a line, a choice, a silence, the phone: the same place, the same stage.
    @Test func resumeAnywhere() throws {
        let original = StoryFixture.director()
        original.resume(); original.advance(); original.advance()   // the choice is on screen
        let data = try StorySaveCoder.encode(original.save)
        let restored = StoryFixture.director(try StorySaveCoder.decode(data))
        restored.resume()
        #expect(restored.stage.line?.nodeID == "l2")
        #expect(restored.stage.actors == original.stage.actors)
        #expect(restored.stage.shot == original.stage.shot)
        restored.choose("yes")
        #expect(restored.save.relationship("boss").trust == 2)

        // On the phone.
        restored.fastForward(); restored.advance()
        if restored.stage.notification != nil { restored.advance() }
        let onPhone = StoryFixture.director(try StorySaveCoder.decode(try StorySaveCoder.encode(restored.save)))
        #expect(onPhone.resume() == [.startCase("story_001")])
        #expect(onPhone.mode == .awaitingCase("story_001"))

        // On the result: never granted twice.
        onPhone.caseFinished("story_001", solved: true, score: 80, found: 4, total: 6)
        onPhone.fastForward()
        guard case .result = onPhone.mode else { Issue.record("expected the result"); return }
        let atResult = StoryFixture.director(try StorySaveCoder.decode(try StorySaveCoder.encode(onPhone.save)))
        let events = atResult.resume()
        guard case .result(let result) = atResult.mode else { Issue.record("expected the result"); return }
        #expect(events.count == 1)
        #expect(result.promotion?.to == .inspecteur)
        #expect(atResult.save.rank == .inspecteur)
        #expect(atResult.save.stats == onPhone.save.stats)
    }

    @Test func quitDuringASilence() throws {
        let d = StoryFixture.director()
        d.resume(); d.advance(); d.advance(); d.choose("silence")
        let again = StoryFixture.director(try StorySaveCoder.decode(try StorySaveCoder.encode(d.save)))
        again.resume()
        #expect(again.stage.line?.text == "Je vois.")
        #expect(again.save.flags.contains("silent"))
    }

    @Test func consequencesAreNotAppliedTwiceOnResume() throws {
        let d = StoryFixture.director()
        d.resume(); d.advance(); d.advance(); d.choose("yes")
        let save = try StorySaveCoder.decode(try StorySaveCoder.encode(d.save))
        let again = StoryFixture.director(save)
        again.resume()
        #expect(again.save.relationship("boss").trust == 2)
    }

    @Test func oldSavesAreMigrated() throws {
        let v0 = """
        {"player":{"firstName":"Camille","lastName":"Arnaud","serviceNumber":"BEN-01234",
          "appearance":{"presentation":"presentation_f","skinTone":"skin_01","hairStyle":"hair_01","hairColor":"haircolor_01",
                        "beard":"beard_none","eyeColor":"eyes_01","outfit":"outfit_01a","accessory":"accessory_none"}},
         "chapter":"chapter_01","step":0,"scene":"scene_a","beat":2,
         "progress":{"rank":"inspecteur","unlocked":["chapter_01","office_card"],"flags":["met_boss"]}}
        """
        let save = try StorySaveCoder.decode(Data(v0.utf8))
        #expect(save.version == StorySave.currentVersion)
        #expect(save.position.sceneID == "scene_a" && save.position.beatIndex == 2)
        #expect(save.rank == .inspecteur)
        #expect(save.unlocks.contains("office_card") && save.flags.contains("met_boss"))
        #expect(save.player.serviceNumber == "BEN-01234")
        #expect(save.player.agreement == .feminine)
        #expect(save.player.appearance.face == "face_01")
        #expect(save.seenScenes.isEmpty && save.history.isEmpty)
        let d = StoryFixture.director(save)
        d.resume()
        #expect(d.mode == .scene)
    }

    @Test func version1SavesAreMigrated() throws {
        let v1 = """
        {"version":1,"player":{"firstName":"Camille","lastName":"Arnaud","serviceNumber":"BEN-04321",
          "appearance":{"presentation":"presentation_m","skinTone":"skin_01","hairStyle":"hair_02","hairColor":"haircolor_01",
                        "beard":"beard_01","eyeColor":"eyes_01","outfit":"outfit_01a","accessory":"accessory_none"}},
         "position":{"chapterID":"chapter_01","stepIndex":3,"beatIndex":0,"showing":"reward"},
         "rank":"inspecteur","unlocks":["chapter_01"],"flags":[],"relationships":{"boss":{"trust":3,"respect":1}},
         "cases":{},"completedChapters":[],"stats":{"casesCompleted":1,"casesSolved":1,"mistakes":0,"cluesFound":3,"chaptersCompleted":0}}
        """
        let save = try StorySaveCoder.decode(Data(v1.utf8))
        #expect(save.version == 2)
        #expect(save.player.agreement == .masculine)
        #expect(save.position.showing == "result")
        #expect(save.relationship("boss").trust == 3)
    }

    @Test func savesFromTheFutureAndGarbageAreRefused() {
        #expect(throws: StorySaveError.tooRecent(99)) { try StorySaveCoder.decode(Data(#"{"version":99}"#.utf8)) }
        #expect(throws: StorySaveError.unreadable) { try StorySaveCoder.decode(Data("not json".utf8)) }
    }

    @Test func aPositionThatNoLongerExistsIsNeverADeadEnd() {
        var save = StorySave(player: StoryFixture.player, firstChapter: "chapter_01")
        save.position = StoryPosition(chapterID: "chapter_99")
        let d = StoryFixture.director(save)
        d.resume()
        #expect(d.mode == .finished)
    }

    @Test func historyIsDatedByTheApp() {
        let d = StoryFixture.director()
        d.addHistory("Première affectation", date: "2026-09-27")
        #expect(d.save.history == [StoryHistoryEntry(date: "2026-09-27", text: "Première affectation")])
        d.markHotspotSeen("card")
        #expect(d.save.seenHotspots == ["card"])
    }
}

@Suite("Story — validator")
struct StoryValidatorTests {
    @Test func theFixtureIsValid() {
        #expect(StoryValidator.validate(StoryFixture.content, knownCases: ["story_001"]) == [])
    }

    @Test func brokenReferencesAreReported() {
        var content = StoryFixture.content
        content.scenes[0].beats.append(StoryFixture.beat(.move) { $0.actor = "ghost"; $0.anchor = "nowhere" })
        content.scenes[0].dialogue[0].next = "missing"
        content.scenes[0].dialogue[1].text = "Salut {player.nickname}"
        let issues = StoryValidator.validate(content, knownCases: [])
        #expect(issues.contains { $0.contains("'ghost' is not a participant") })
        #expect(issues.contains { $0.contains("unknown anchor 'nowhere'") })
        #expect(issues.contains { $0.contains("unknown next 'missing'") })
        #expect(issues.contains { $0.contains("unknown placeholder {player.nickname}") })
        #expect(issues.contains { $0.contains("unknown case 'story_001'") })
    }

    @Test func theGrammarOfShotsIsChecked() {
        var content = StoryFixture.content
        // Opens on a medium, a camera that is not in the room, a forbidden transition, no OBJECT FOCUS before the phone.
        content.scenes[0].beats[1].shot = CameraShot(kind: .medium, camera: "cam_ms", subject: "boss")
        content.scenes[0].beats.append(StoryFixture.beat(.camera) { $0.shot = CameraShot(kind: .medium, camera: "cam_drone", subject: "boss") })
        content.scenes[0].beats.append(StoryFixture.beat(.transition) { $0.style = "wipe" })
        content.locations[0].cameras.append(CameraAnchor(id: "cam_out", x: 9, y: 1, z: 0, lookX: 0, lookY: 1, lookZ: 0, focal: 24, fov: nil))
        let issues = StoryValidator.validate(content, knownCases: ["story_001"])
        #expect(issues.contains { $0.contains("the first shot must be WIDE") })
        #expect(issues.contains { $0.contains("unknown camera 'cam_drone'") })
        #expect(issues.contains { $0.contains("transition 'wipe'") })
        #expect(issues.contains { $0.contains("must be an OBJECT FOCUS") })
        #expect(issues.contains { $0.contains("'cam_out' is outside the room") })
        #expect(issues.contains { $0.contains("focal 24.0 mm is not allowed") })
    }

    @Test func eachSceneHasASilence() {
        var content = StoryFixture.content
        content.scenes[1].beats.remove(at: 2)
        #expect(StoryValidator.validate(content, knownCases: ["story_001"]).contains { $0.contains("silent shot of 2 to 4 s") })
    }

    @Test func loopsAreReported() {
        var content = StoryFixture.content
        content.scenes[1].dialogue[0].next = "ok"
        #expect(StoryValidator.validate(content, knownCases: ["story_001"]).contains { $0.contains("loop") })
    }
}
