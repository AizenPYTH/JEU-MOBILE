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
