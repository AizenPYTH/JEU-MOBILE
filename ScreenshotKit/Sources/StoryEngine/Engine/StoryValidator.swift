import Foundation

/// Cross-checks the story content: every scene, room, anchor, camera, prop, person, line, choice,
/// variant, placeholder and unlock it names exists. Content bugs fail the tests and StoryLint
/// (CaseLint prints them too), never the game.
public enum StoryValidator {
    /// `knownCases`: the ids of the investigations the game ships (nil: not checked).
    public static func validate(_ content: StoryContent, knownCases: Set<String>? = nil) -> [String] {
        var issues: [String] = []
        func fail(_ s: String) { issues.append(s) }

        // Characters.
        let catalog = content.catalog
        var variantIDs = Set<String>()
        for v in catalog.variants {
            if !variantIDs.insert(v.id).inserted { fail("variant '\(v.id)' is defined twice") }
            if let color = v.color, !isColor(color) { fail("variant '\(v.id)': bad colour \(color)") }
            if let accent = v.accent, !isColor(accent) { fail("variant '\(v.id)': bad accent \(accent)") }
        }
        let presentations = catalog.variants.filter { $0.slot == .presentation }.map(\.id)
        if presentations.isEmpty { fail("no presentation variant") }
        for p in presentations {
            for slot in AppearanceSlot.allCases where slot != .presentation {
                if catalog.options(for: slot, presentation: p, unlocked: []).isEmpty {
                    fail("presentation '\(p)' has no free option for \(slot.rawValue)")
                }
            }
        }
        if !catalog.isValid(catalog.defaultAppearance, unlocked: []) { fail("the default appearance is not valid") }

        // People.
        var npcIDs = Set<String>()
        for npc in content.npcs {
            if !npcIDs.insert(npc.id).inserted { fail("NPC '\(npc.id)' is defined twice") }
            if npc.id == "player" || npc.id == "narrator" { fail("'\(npc.id)' is reserved") }
            for slot in AppearanceSlot.allCases where catalog.variant(npc.appearance[slot])?.slot != slot {
                fail("NPC '\(npc.id)': unknown \(slot.rawValue) '\(npc.appearance[slot])'")
            }
        }

        // Rooms.
        var locationIDs = Set<String>()
        for location in content.locations {
            if !locationIDs.insert(location.id).inserted { fail("location '\(location.id)' is defined twice") }
            if location.size.count != 3 || location.size.contains(where: { $0 <= 0 }) { fail("location '\(location.id)': size needs 3 positive values") }
            for color in [location.wallColor, location.floorColor] + [location.accentColor].compactMap({ $0 }) where !isColor(color) {
                fail("location '\(location.id)': bad colour \(color)")
            }
            if location.cameras.isEmpty { fail("location '\(location.id)' has no camera") }
            let half = location.size.count == 3 ? (location.size[0] / 2, location.size[1] / 2) : (0, 0)
            var ids = Set<String>()
            for a in location.anchors {
                if !ids.insert(a.id).inserted { fail("location '\(location.id)': anchor '\(a.id)' twice") }
                if abs(a.x) > half.0 + 0.01 || abs(a.z) > half.1 + 0.01 { fail("location '\(location.id)': anchor '\(a.id)' is outside the room") }
            }
            var cameraIDs = Set<String>()
            for c in location.cameras {
                if !cameraIDs.insert(c.id).inserted { fail("location '\(location.id)': camera '\(c.id)' twice") }
                if abs(c.x) > half.0 || abs(c.z) > half.1 || c.y <= 0 || c.y >= location.size[2] {
                    fail("location '\(location.id)': camera '\(c.id)' is outside the room")
                }
                if !c.id.hasPrefix("cam_") { fail("location '\(location.id)': camera '\(c.id)' must be named cam_…") }
                if let focal = c.focal, !CameraAnchor.focals.contains(focal) { fail("camera '\(c.id)': focal \(focal) mm is not allowed (28, 35, 50, 85, 100)") }
                if c.focal == nil && c.fov == nil { fail("camera '\(c.id)' needs a focal") }
            }
            var propIDs = Set<String>()
            for p in location.props {
                if !propIDs.insert(p.id).inserted { fail("location '\(location.id)': prop '\(p.id)' twice") }
                if let color = p.color, !isColor(color) { fail("prop '\(p.id)': bad colour \(color)") }
                if let label = p.label { issues += placeholders(label, where: "prop '\(p.id)'") }
                if let level = p.level, !(1...4).contains(level) { fail("prop '\(p.id)': office level \(level) is not 1–4") }
                if let cam = p.hotspot?.camera, location.camera(cam) == nil { fail("prop '\(p.id)': unknown hotspot camera '\(cam)'") }
            }
        }

        // Scenes.
        var sceneIDs = Set<String>()
        for scene in content.scenes {
            if !sceneIDs.insert(scene.id).inserted { fail("scene '\(scene.id)' is defined twice") }
            guard let location = content.location(scene.location) else { fail("scene '\(scene.id)': unknown location '\(scene.location)'"); continue }
            let cast = Set(scene.participants)
            for p in scene.participants where p != "player" && !npcIDs.contains(p) { fail("scene '\(scene.id)': unknown participant '\(p)'") }
            if scene.participants.count > 3 { fail("scene '\(scene.id)': more than 3 people on screen") }
            if let place = scene.place { issues += placeholders(place, where: "scene '\(scene.id)' place") }
            // Grammar (STORY_SCENES §2): a WIDE first, never more than 2 CLOSE in a row, one silent shot.
            let shots = scene.beats.compactMap { $0.kind == .camera ? $0.shot : nil }
            if let first = shots.first, first.kind != .wide { fail("scene '\(scene.id)': the first shot must be WIDE") }
            if shots.isEmpty { fail("scene '\(scene.id)': no shot") }
            var closes = 0
            for shot in shots {
                closes = shot.kind == .closeUp ? closes + 1 : 0
                if closes > 2 { fail("scene '\(scene.id)': more than 2 CLOSE shots in a row"); break }
            }
            if !scene.beats.contains(where: { $0.kind == .wait && (2...4).contains($0.seconds ?? 0) }) {
                fail("scene '\(scene.id)': needs a silent shot of 2 to 4 s")
            }
            var nodeIDs = Set<String>()
            for n in scene.dialogue where !nodeIDs.insert(n.id).inserted { fail("scene '\(scene.id)': line '\(n.id)' twice") }
            for (i, beat) in scene.beats.enumerated() {
                let at = "scene '\(scene.id)' beat \(i + 1) (\(beat.kind.rawValue))"
                if let actor = beat.actor, !cast.contains(actor) { fail("\(at): '\(actor)' is not a participant") }
                if let anchor = beat.anchor, location.anchor(anchor) == nil { fail("\(at): unknown anchor '\(anchor)'") }
                switch beat.kind {
                case .place, .enter, .move:
                    if beat.actor == nil || beat.anchor == nil { fail("\(at): needs 'actor' and 'anchor'") }
                case .exit, .animate:
                    if beat.actor == nil { fail("\(at): needs 'actor'") }
                    if beat.kind == .animate && beat.animation == nil { fail("\(at): needs 'animation'") }
                case .face:
                    if let target = beat.target, !cast.contains(target), location.prop(target) == nil { fail("\(at): unknown target '\(target)'") }
                case .camera:
                    guard let shot = beat.shot else { fail("\(at): needs 'shot'"); break }
                    for person in [shot.subject, shot.other].compactMap({ $0 }) where !cast.contains(person) { fail("\(at): '\(person)' is not in the scene") }
                    issues += shotIssues(shot, location: location, cast: cast, where: at)
                case .dialogue:
                    if let node = beat.node { if !nodeIDs.contains(node) { fail("\(at): unknown line '\(node)'") } } else { fail("\(at): needs 'node'") }
                case .title:
                    if (beat.text ?? "").isEmpty { fail("\(at): needs 'text'") }
                    issues += placeholders(beat.text ?? "", where: at)
                case .notification:
                    if (beat.title ?? "").isEmpty { fail("\(at): needs 'title'") }
                    issues += placeholders((beat.title ?? "") + (beat.text ?? ""), where: at)
                case .effect:
                    if (beat.effects ?? []).isEmpty { fail("\(at): needs 'effects'") }
                case .sound, .ambience:
                    if beat.sound == nil { fail("\(at): needs 'sound'") }
                case .show, .hide:
                    if let target = beat.target { if location.prop(target) == nil { fail("\(at): unknown prop '\(target)'") } } else { fail("\(at): needs 'target'") }
                case .transition:
                    if let style = beat.style, !SceneBeat.transitionStyles.contains(style) { fail("\(at): transition '\(style)' is not allowed (cut, dissolve, fade)") }
                case .wait:
                    break
                }
                issues += effectIssues(beat.effects ?? [], npcs: npcIDs, where: at)
            }
            for node in scene.dialogue {
                let at = "scene '\(scene.id)' line '\(node.id)'"
                if node.speaker != "player", node.speaker != "narrator", !cast.contains(node.speaker) { fail("\(at): speaker '\(node.speaker)' is not in the scene") }
                if let next = node.next, !nodeIDs.contains(next) { fail("\(at): unknown next '\(next)'") }
                if node.text.trimmingCharacters(in: .whitespaces).isEmpty { fail("\(at): empty text") }
                issues += placeholders(node.text, where: at)
                issues += effectIssues(node.effects ?? [], npcs: npcIDs, where: at)
                if let shot = node.shot { issues += shotIssues(shot, location: location, cast: cast, where: at) }
                var choiceIDs = Set<String>()
                if (node.choices ?? []).filter({ $0.silent == true }).count > 1 { fail("\(at): more than one silence") }
                for choice in node.choices ?? [] {
                    if !choiceIDs.insert(choice.id).inserted { fail("\(at): choice '\(choice.id)' twice") }
                    if let shot = choice.shot { issues += shotIssues(shot, location: location, cast: cast, where: "\(at) choice '\(choice.id)'") }
                    if let sentence = choice.remember { issues += placeholders(sentence, where: "\(at) choice '\(choice.id)' remember") }
                    if let next = choice.next, !nodeIDs.contains(next) { fail("\(at) choice '\(choice.id)': unknown next '\(next)'") }
                    issues += placeholders(choice.text, where: "\(at) choice '\(choice.id)'")
                    issues += effectIssues(choice.effects ?? [], npcs: npcIDs, where: "\(at) choice '\(choice.id)'")
                }
                if let choices = node.choices, choices.count > 4 { fail("\(at): more than 4 choices") }
                if let choices = node.choices, !choices.isEmpty, !choices.contains(where: { $0.condition == nil }) {
                    fail("\(at): at least one choice must always be available")
                }
            }
            issues += loops(in: scene)
        }

        // Campaign.
        var chapterIDs = Set<String>()
        var rewardUnlocks = Set<String>()
        for chapter in content.campaign.chapters {
            if !chapterIDs.insert(chapter.id).inserted { fail("chapter '\(chapter.id)' is defined twice") }
            if chapter.status == .playable && chapter.steps.isEmpty { fail("chapter '\(chapter.id)' is playable but has no step") }
            var stepIDs = Set<String>()
            for step in chapter.steps {
                let at = "chapter '\(chapter.id)' step '\(step.id)'"
                if !stepIDs.insert(step.id).inserted { fail("\(at) twice") }
                switch step.kind {
                case .scene:
                    if let id = step.scene { if !sceneIDs.contains(id) { fail("\(at): unknown scene '\(id)'") } } else { fail("\(at): needs 'scene'") }
                case .investigation:
                    if let id = step.caseID {
                        if let known = knownCases, !known.contains(id) { fail("\(at): unknown case '\(id)'") }
                    } else { fail("\(at): needs 'caseID'") }
                case .result:
                    rewardUnlocks.formUnion(step.reward?.allUnlocks ?? [])
                case .office:
                    break
                }
            }
            // OBJECT FOCUS before going to the phone (T-SIG-1).
            for (i, step) in chapter.steps.enumerated() where step.kind == .investigation && i > 0 {
                let before = chapter.steps[i - 1]
                if before.kind == .scene, let scene = before.scene.flatMap(content.scene),
                   scene.beats.last(where: { $0.kind == .camera })?.shot?.kind != .focusObject {
                    fail("scene '\(scene.id)': the last shot before the phone must be an OBJECT FOCUS")
                }
            }
            if chapter.status == .playable {
                if !chapter.steps.contains(where: { $0.kind == .result }) { fail("chapter '\(chapter.id)' has no result step") }
                if chapter.summary == nil || chapter.summaryUnsolved == nil { fail("chapter '\(chapter.id)' needs 'summary' and 'summaryUnsolved'") }
            }
        }
        // Career: from ENQUÊTEUR, ranks in order, chapters that exist.
        let career = content.campaign.career
        if career.first?.rank != .enqueteur || career.first?.cases != 0 { fail("the career must start at ENQUÊTEUR with 0 case") }
        if career.map(\.rank) != career.map(\.rank).sorted() || Set(career.map(\.rank)).count != career.count { fail("career ranks must increase") }
        // A tier may wait for a chapter not written yet (EXPÉRIMENTÉ: chapter 7).
        for tier in career { if let n = tier.chapter, n < 1 { fail("career \(tier.rank.rawValue): bad chapter \(n)") } }
        if content.campaign.chapters.first?.status != .playable { fail("the first chapter must be playable") }
        let numbers = content.campaign.chapters.map(\.number)
        if numbers != numbers.sorted() || Set(numbers).count != numbers.count { fail("chapter numbers must increase") }
        // Every locked variant and every office prop can be earned.
        for scene in content.scenes {
            for effect in scene.beats.flatMap({ $0.effects ?? [] }) + scene.dialogue.flatMap({ ($0.effects ?? []) + ($0.choices ?? []).flatMap { $0.effects ?? [] } })
            where effect.kind == .unlock { rewardUnlocks.insert(effect.id ?? "") }
        }
        for v in catalog.variants { if let u = v.unlock, !rewardUnlocks.contains(u) { fail("variant '\(v.id)' needs '\(u)', which nothing unlocks") } }
        for location in content.locations {
            for p in location.props { if let r = p.requires, !rewardUnlocks.contains(r) { fail("prop '\(p.id)' needs '\(r)', which nothing unlocks") } }
        }
        return issues
    }

    /// Every shot is one of the room's named cameras, on people of the scene.
    static func shotIssues(_ shot: CameraShot, location: StoryLocation, cast: Set<String>, where at: String) -> [String] {
        var issues: [String] = []
        for person in [shot.subject, shot.other].compactMap({ $0 }) where !cast.contains(person) { issues.append("\(at): '\(person)' is not in the scene") }
        if let prop = shot.prop, location.prop(prop) == nil { issues.append("\(at): unknown prop '\(prop)'") }
        if let cam = shot.camera {
            if location.camera(cam) == nil { issues.append("\(at): unknown camera '\(cam)'") }
        } else {
            issues.append("\(at): the shot needs one of the room's cameras")
        }
        if shot.kind == .focusObject && shot.prop == nil { issues.append("\(at): OBJECT FOCUS needs 'prop'") }
        return issues
    }

    static func isColor(_ s: String) -> Bool {
        s.count == 7 && s.hasPrefix("#") && s.dropFirst().allSatisfy(\.isHexDigit)
    }

    /// « {…} » placeholders must be known ones or gendered words {g:…|…}.
    static func placeholders(_ text: String, where at: String) -> [String] {
        var issues: [String] = []
        var rest = Substring(text)
        while let open = rest.firstIndex(of: "{") {
            guard let close = rest[open...].firstIndex(of: "}") else { issues.append("\(at): unclosed '{'"); break }
            let token = String(rest[open...close])
            if !token.hasPrefix("{g:") && !StoryText.knownPlaceholders.contains(token) { issues.append("\(at): unknown placeholder \(token)") }
            rest = rest[rest.index(after: close)...]
        }
        return issues
    }

    static func effectIssues(_ effects: [StoryEffect], npcs: Set<String>, where at: String) -> [String] {
        effects.compactMap { e in
            switch e.kind {
            case .trust, .respect: return e.npc.map { npcs.contains($0) ? nil : "\(at): unknown NPC '\($0)'" } ?? "\(at): \(e.kind.rawValue) needs 'npc'"
            case .flag: return e.flag == nil ? "\(at): flag needs 'flag'" : nil
            case .unlock: return e.id == nil ? "\(at): unlock needs 'id'" : nil
            }
        }
    }

    /// A conversation must always end: no line can lead back to itself through `next` alone.
    static func loops(in scene: StoryScene) -> [String] {
        var issues: [String] = []
        for start in scene.dialogue {
            var seen = Set<String>()
            var id: String? = start.id
            while let current = id, let node = scene.node(current) {
                if !seen.insert(current).inserted { issues.append("scene '\(scene.id)': the lines loop at '\(current)'"); break }
                id = (node.choices ?? []).isEmpty ? node.next : nil
            }
        }
        return Array(Set(issues)).sorted()
    }
}
