import Foundation
import Testing
import CaseEngine
import CaseLibrary
import StoryEngine
import StoryLibrary

/// Guards the story shipped with the game (Resources/Story): valid, playable to the end of every
/// playable chapter, and wired to investigations that exist.
@Suite("Shipped story")
struct ShippedStoryTests {
    static func content() throws -> StoryContent { try StoryLibrary.load() }

    @Test func theStoryIsValid() throws {
        let cases = Set(try CaseLibrary.loadCases().map(\.id))
        let issues = StoryValidator.validate(try Self.content(), knownCases: cases)
        #expect(issues.isEmpty, "\(issues.joined(separator: "\n"))")
    }

    @Test func theRoomsOfTheBENExist() throws {
        let ids = Set(try Self.content().locations.map(\.id))
        for id in ["ENV_BEN_CORRIDOR", "ENV_BEN_OFFICE_LACAZE", "ENV_BEN_OFFICE_PLAYER", "ENV_BEN_OPENSPACE", "ENV_BEN_ARCHIVES",
                   "ENV_BEN_INTERROGATION", "ENV_BEN_BRIEFING"] {
            #expect(ids.contains(id), "\(id)")
        }
        let content = try Self.content()
        for (id, name) in [("lacaze", "Lacaze"), ("ines", "Carvalho"), ("aubrac", "Aubrac"), ("colette", "Vidal")] {
            #expect(content.npc(id)?.lastName == name)
        }
        // Élise and Vincent are the starting models of the player, never people of the BEN.
        #expect(content.catalog.templates.map(\.id) == ["elise", "vincent"])
        #expect(content.npc("elise") == nil && content.npc("vincent") == nil)
    }

    /// CHARACTER_CUSTOMIZATION: 2 bases, 6 of each option per base, 4 outfits × 2 variants.
    @Test func theCreatorOffersTheHandoffOptions() throws {
        let catalog = try Self.content().catalog
        for base in ["presentation_f", "presentation_m"] {
            for slot in [AppearanceSlot.skinTone, .face, .hairStyle, .hairColor, .eyeColor] {
                #expect(catalog.options(for: slot, presentation: base, unlocked: []).count == 6, "\(base) \(slot)")
            }
            let outfits = catalog.options(for: .outfit, presentation: base, unlocked: [])
            #expect(outfits.count == 8)
            #expect(Set(outfits.compactMap(\.group)).count == 4)
        }
        #expect(catalog.options(for: .beard, presentation: "presentation_m", unlocked: []).count == 4)
        for template in catalog.templates { #expect(catalog.isValid(template.appearance, unlocked: []), "\(template.id)") }
    }

    /// Chapter 1 follows STORY_SCENES §5: the corridor, office 312, #001, the return, the result, my office.
    @Test func chapterOneIsTheFirstAssignment() throws {
        let chapter = try #require(try Self.content().campaign.chapter("chapter_01"))
        #expect(chapter.steps.map(\.kind) == [.scene, .scene, .investigation, .scene, .result, .scene, .office])
        #expect(chapter.steps.compactMap(\.caseID) == ["case_001"])
        #expect(chapter.steps.compactMap(\.scene) == ["S01-01", "S01-01B", "S01-02", "S01-03"])
    }

    /// Every playable chapter can be played to its end, whatever the player answers and whatever
    /// the investigations give — and the first chapter moves the career on.
    @Test func everyPlayableChapterCanBeFinished() throws {
        let content = try Self.content()
        let player = StoryPlayer(firstName: "Camille", lastName: "Arnaud", appearance: content.catalog.defaultAppearance)
        for chapter in content.campaign.chapters where chapter.status == .playable {
            for (choiceIndex, solved) in [(0, true), (1, false), (2, true)] {
                var save = StorySave(player: player, firstChapter: content.campaign.chapters[0].id)
                save.unlocks.insert(chapter.id)
                let d = StoryDirector(content: content, save: save)
                d.startChapter(chapter.id)
                var steps = 0
                while steps < 2000 {
                    steps += 1
                    switch d.mode {
                    case .scene:
                        if let line = d.stage.line, !line.choices.isEmpty {
                            d.choose(line.choices[min(choiceIndex, line.choices.count - 1)].id)
                        } else {
                            d.advance()
                        }
                    case .awaitingCase(let id):
                        let file = try #require(try CaseLibrary.loadCases().first { $0.id == id }, "\(chapter.id): no case \(id)")
                        d.caseFinished(id, solved: solved, score: solved ? 80 : 20, found: 3, total: file.evidence.count)
                    case .result, .office:
                        d.advance()
                    case .chapterComplete, .finished, .idle:
                        steps = 5000
                    }
                }
                #expect(d.mode == .chapterComplete(chapter.id), "\(chapter.id) (choices \(choiceIndex), solved \(solved)) ended at \(d.mode)")
                if chapter.number == 1 {
                    // INSPECTEUR: one solved case and chapter 1 (CHARACTER_CUSTOMIZATION §6).
                    #expect(d.save.rank == (solved ? .inspecteur : .enqueteur), "chapter 1, solved \(solved)")
                    #expect(d.save.unlocks.isSuperset(of: ["office_card", "office_01"]), "chapter 1 opens the office")
                }
            }
        }
    }

    /// Every shot frames what it is about (STORY_SCENES §2), read from the named cameras and the
    /// people's places: the subject's head is in the portrait frame, nobody stands against the lens,
    /// a CLOSE shows shoulders to head (not a face filling the screen), and an over-the-shoulder
    /// shot keeps the player's shoulder at the frame's edge with the other person in it.
    @Test func shotsFrameTheirSubject() throws {
        let content = try Self.content()
        let aspect = 390.0 / 844.0
        func head(_ actor: String, _ a: StageAnchor) -> (Double, Double, Double) {
            let height = actor == "player" ? 1.74 : (content.npc(actor)?.height ?? 1.75)
            return (a.x, (1.66 - (a.seated == true ? 0.42 : 0)) * height / 1.75 + 0.02, a.z)
        }
        /// (x across the width, y across the height, both −1…1; depth; head's share of the frame height)
        func project(_ c: CameraAnchor, _ p: (Double, Double, Double)) -> (Double, Double, Double, Double)? {
            var f = (c.lookX - c.x, c.lookY - c.y, c.lookZ - c.z)
            let n = (f.0 * f.0 + f.1 * f.1 + f.2 * f.2).squareRoot()
            f = (f.0 / n, f.1 / n, f.2 / n)
            let rn = (f.2 * f.2 + f.0 * f.0).squareRoot()
            guard rn > 1e-6 else { return nil }
            let r = (-f.2 / rn, 0.0, f.0 / rn)
            let u = (r.1 * f.2 - r.2 * f.1, r.2 * f.0 - r.0 * f.2, r.0 * f.1 - r.1 * f.0)
            let d = (p.0 - c.x, p.1 - c.y, p.2 - c.z)
            let depth = d.0 * f.0 + d.1 * f.1 + d.2 * f.2
            guard depth > 0.05 else { return nil }
            let th = tan(c.verticalFOV * .pi / 360), tw = th * aspect
            return ((d.0 * r.0 + d.2 * r.2) / depth / tw, (d.0 * u.0 + d.1 * u.1 + d.2 * u.2) / depth / th, depth, 0.25 / (2 * th * depth))
        }
        var issues: [String] = []
        for scene in content.scenes {
            guard let location = content.location(scene.location) else { continue }
            var places: [String: StageAnchor] = [:]
            for (i, beat) in scene.beats.enumerated() {
                switch beat.kind {
                case .place, .enter, .move:
                    if let actor = beat.actor, let anchor = beat.anchor.flatMap(location.anchor) { places[actor] = anchor }
                case .exit:
                    if let actor = beat.actor { places[actor] = nil }
                default: break
                }
                guard beat.kind == .camera, let shot = beat.shot, let camera = shot.camera.flatMap(location.camera) else { continue }
                let at = "\(scene.id) beat \(i + 1) \(shot.kind.rawValue) \(camera.id)"
                for (actor, anchor) in places {
                    guard let (x, y, depth, share) = project(camera, head(actor, anchor)) else { continue }
                    let inside = abs(x) < 1 && abs(y) < 1
                    if depth < 0.7 && abs(x) < 1.6 && abs(y) < 1.6 { issues.append("\(at): \(actor) against the camera") }
                    if shot.kind == .overShoulder && actor == shot.subject {
                        if inside && share > 0.45 { issues.append("\(at): \(actor)'s shoulder fills the frame") }
                        else if !(0.6..<1.5).contains(abs(x)) { issues.append("\(at): \(actor)'s shoulder not at the edge") }
                    } else if actor == shot.subject || (shot.kind == .overShoulder && actor == shot.other) {
                        if !inside { issues.append("\(at): \(actor) out of frame") }
                        if shot.kind == .closeUp && share > 0.42 { issues.append("\(at): CLOSE too tight on \(actor)") }
                    } else if inside && share > 0.55 {
                        issues.append("\(at): \(actor) fills the frame")
                    }
                }
            }
        }
        #expect(issues.isEmpty, "\(issues.joined(separator: "\n"))")
    }

    @Test func scenesStayShort() throws {
        for scene in try Self.content().scenes {
            let words = scene.dialogue.map { $0.text.split(separator: " ").count }.reduce(0, +)
            // About 2.5 words per second of reading, plus the pauses: 30 s to 3 min.
            let pauses = scene.beats.compactMap(\.seconds).reduce(0, +)
            let seconds = Double(words) / 2.5 + pauses
            #expect(seconds <= 200, "\(scene.id): ~\(Int(seconds)) s")
        }
    }

    @Test func storyCasesAreOnlyInTheStory() throws {
        let content = try Self.content()
        let caseIDs = Set(content.campaign.chapters.flatMap(\.steps).compactMap(\.caseID))
        for file in try CaseLibrary.loadCases() where file.isStory {
            #expect(caseIDs.contains(file.id), "\(file.id) is a story case no chapter plays")
        }
    }
}
