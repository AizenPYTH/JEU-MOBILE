import Foundation

// The story's state machine. It plays the campaign step by step (scenes, investigations, rewards,
// the office), applies the beats of a scene, walks the dialogue, applies consequences, and keeps
// `save` up to date after every action — so quitting anywhere (a line, a choice, a pause, the
// phone) resumes at the same place. Deterministic: the same save and the same choices always give
// the same stage. It never draws anything: the presentation reads `stage` and the returned events.

/// Where a character is on the stage.
public struct ActorState: Hashable, Sendable {
    public var x: Double
    public var z: Double
    public var facing: Double
    public var visible: Bool
    public var seated: Bool
    public var anchor: String?
    /// The last animation played (the stage settles on its final pose).
    public var pose: String?

    /// Public so the presentation can stage a person outside a scene (the hub's hero shot).
    public init(x: Double, z: Double, facing: Double, visible: Bool, seated: Bool, anchor: String? = nil, pose: String? = nil) {
        self.x = x
        self.z = z
        self.facing = facing
        self.visible = visible
        self.seated = seated
        self.anchor = anchor
        self.pose = pose
    }
}

public struct ResolvedChoice: Hashable, Sendable, Identifiable {
    public var id: String
    public var text: String
    /// The silence (« Ne rien dire »).
    public var silent: Bool
    /// The answer given the first time (a replayed chapter shows it).
    public var chosenBefore: Bool
}

/// A line ready to show: the player's name in it, the speaker's name, the choices still open.
public struct ResolvedLine: Hashable, Sendable {
    public var nodeID: String
    public var speaker: String
    /// « Bernard Lacaze », the player's full name, nil for the narrator.
    public var speakerName: String?
    /// « Commandant »… (nil for the player and the narrator).
    public var speakerRole: String?
    public var text: String
    public var emotion: String
    public var animation: String?
    public var choices: [ResolvedChoice]
    public var voice: String?
}

public struct StoryNotice: Hashable, Sendable {
    public var title: String
    public var text: String
    public var app: String
}

/// Everything the stage must show right now.
public struct StageState: Hashable, Sendable {
    public var sceneID: String?
    public var location: String?
    public var actors: [String: ActorState] = [:]
    public var shot: CameraShot?
    public var ambience: String?
    public var line: ResolvedLine?
    public var notification: StoryNotice?
    public var titleCard: String?
    /// Hidden props shown by the scene, and props taken away.
    public var shownProps: Set<String> = []
    public var removedProps: Set<String> = []

    public init() {}
}

/// What just happened, for the presentation to animate.
public enum StoryEvent: Hashable, Sendable {
    case sceneStarted(scene: String, location: String)
    case actorPlaced(String)
    case actorEntered(String)
    case actorMoved(String)
    case actorLeft(String)
    case actorFaced(String, target: String)
    case animated(String, animation: String)
    case camera(CameraShot)
    case line(ResolvedLine)
    case sound(String)
    case ambience(String)
    case transition(style: String, seconds: Double)
    case wait(Double)
    case notification(StoryNotice)
    case titleCard(String, seconds: Double)
    case effects([StoryEffect])
    case sceneEnded(String)
    case startCase(String)
    case result(StoryChapterResult)
    case office
    case chapterCompleted(String)
    /// A replayed chapter is over: the player is back where they were.
    case replayEnded
}

/// The end of a chapter as the result screens show it (h16, h17, h18).
public struct StoryChapterResult: Hashable, Sendable {
    public var chapterID: String
    /// Every investigation of the chapter was solved (else: « CLASSÉ », the unsolved summary).
    public var solved: Bool
    public var casesSolved: Int
    public var cases: Int
    public var alibis: Int
    public var seconds: Int
    /// « VOS DÉCISIONS ».
    public var decisions: [String]
    public var reward: StoryReward?
    /// A rank reached (then « Avancement de service »).
    public var promotion: StoryPromotion?
    public var rank: StoryRank
    /// The next rank and what it takes (nil: top rank).
    public var nextTier: CareerTier?
    /// Cases solved, all modes (the boxes of h17).
    public var solvedCount: Int
}

public enum DirectorMode: Hashable, Sendable {
    /// Nothing started (before `resume()`).
    case idle
    /// A scene is playing.
    case scene
    /// The phone is on: an investigation is being played.
    case awaitingCase(String)
    /// The chapter's result, career and reward screens are on (h16–h18).
    case result(StoryChapterResult)
    /// The player's office is open.
    case office
    /// The chapter is over (the hub offers the next one).
    case chapterComplete(String)
    /// The save points at a chapter the content does not have (never a dead end: the hub).
    case finished
}

public final class StoryDirector {
    public let content: StoryContent
    public private(set) var save: StorySave
    public private(set) var stage = StageState()
    public private(set) var mode: DirectorMode = .idle
    /// The current blocking beat ends by itself after this many seconds (wait, transition, title).
    public private(set) var autoAdvance: Double?
    /// Cases solved outside the story (ENQUÊTES), by id: the career counts every mode.
    public var externalSolved: Set<String> = []
    private var pendingBeatsAfterPause = false

    public init(content: StoryContent, save: StorySave) {
        self.content = content
        self.save = save
    }

    public var chapter: StoryChapter? { content.campaign.chapter(save.position.chapterID) }
    public var scene: StoryScene? { save.position.sceneID.flatMap(content.scene) }
    public var location: StoryLocation? { stage.location.flatMap(content.location) }

    // MARK: - Start and resume

    /// Puts the director where the save says (rebuilding the stage of a scene in progress).
    @discardableResult
    public func resume() -> [StoryEvent] {
        let position = save.position
        guard let chapter else { mode = .finished; return [] }
        if position.stepIndex >= chapter.steps.count { mode = .chapterComplete(chapter.id); return [] }
        if let caseID = position.awaitingCase { mode = .awaitingCase(caseID); return [.startCase(caseID)] }
        if position.showing == "result" {
            let result = makeResult(chapter)
            mode = .result(result)
            return [.result(result)]
        }
        if position.showing == "office" { mode = .office; return [.office] }
        if let sceneID = position.sceneID, let scene = content.scene(sceneID) {
            mode = .scene
            stage = StageState()
            stage.sceneID = scene.id
            stage.location = scene.location
            stage.ambience = content.location(scene.location)?.ambience
            // Replay what was already played, silently (no consequence is applied twice).
            for beat in scene.beats.prefix(position.beatIndex) where holds(beat.condition) {
                _ = apply(beat, in: scene, silent: true)
            }
            var events: [StoryEvent] = [.sceneStarted(scene: scene.id, location: scene.location)]
            if let nodeID = position.nodeID, let line = resolve(nodeID, in: scene) {
                if let shot = scene.node(nodeID)?.shot { stage.shot = shot }
                stage.line = line
                events.append(.line(line))
                return events
            }
            if let after = position.afterPause {
                // Quit during the silence that follows an answer: the conversation goes on.
                save.position.afterPause = nil
                return events + continueDialogue(from: after, in: scene)
            }
            return events + runBeats()
        }
        return enterStep(position.stepIndex)
    }

    /// Starts a chapter (unlocked and playable) from its first step.
    @discardableResult
    public func startChapter(_ id: String) -> [StoryEvent] {
        guard let chapter = content.campaign.chapter(id), chapter.status == .playable, save.unlocks.contains(id) else { return [] }
        save.position = StoryPosition(chapterID: chapter.id)
        save.lastCaseSolved = nil
        return enterStep(0)
    }

    /// « Rejouer un chapitre » (h19): its scenes again, the answers given shown, nothing counts
    /// (no consequence, no reward, investigations skipped). At the end, back where the player was.
    @discardableResult
    public func replayChapter(_ id: String) -> [StoryEvent] {
        guard save.replay == nil, save.completedChapters.contains(id), let chapter = content.campaign.chapter(id),
              chapter.status == .playable else { return [] }
        save.replay = StoryReplay(chapterID: id, returnPosition: save.position, returnLastCaseSolved: save.lastCaseSolved)
        save.position = StoryPosition(chapterID: id)
        save.lastCaseSolved = save.cases.values.contains { $0.solved }
        return enterStep(0)
    }

    public var isReplaying: Bool { save.replay != nil }

    /// A scene already played to the end can be passed (« PASSER »).
    public var canSkipScene: Bool {
        guard case .scene = mode, let id = save.position.sceneID else { return false }
        return save.seenScenes.contains(id)
    }

    /// « PASSER » on a scene already seen: straight to its end, the earlier answers kept.
    @discardableResult
    public func skipScene() -> [StoryEvent] {
        guard canSkipScene, let sceneID = save.position.sceneID else { return [] }
        var events: [StoryEvent] = []
        for _ in 0..<1000 {
            guard case .scene = mode, save.position.sceneID == sceneID else { break }
            if let line = stage.line, !line.choices.isEmpty {
                let pick = line.choices.first(where: \.chosenBefore) ?? line.choices.first(where: \.silent) ?? line.choices[0]
                events += choose(pick.id)
            } else {
                events += advance()
            }
        }
        return events
    }

    // MARK: - Career

    /// Cases solved, all modes, each counted once (ALIBI checks are handled, never solved).
    public var solvedCount: Int {
        externalSolved.union(save.cases.values.filter { $0.solved && $0.alibi != true }.map(\.caseID)).count
    }

    /// The player's office level (1–4): the rank's.
    public var officeLevel: Int { (StoryRank.allCases.firstIndex(of: save.rank) ?? 0) + 1 }

    /// Applies the career rules (cases solved AND chapter reached). A rank reached is kept in
    /// `save.promotion` until the career screen showed it. Never goes down.
    @discardableResult
    public func refreshCareer() -> StoryPromotion? {
        guard save.replay == nil else { return nil }
        let earned = content.campaign.rank(solved: solvedCount, chapters: save.finishedChapterNumbers(in: content.campaign))
        guard earned > save.rank else { return nil }
        let promotion = StoryPromotion(from: save.promotion?.from ?? save.rank, to: earned)
        save.rank = earned
        save.promotion = promotion
        return promotion
    }

    /// The career screen showed the promotion.
    public func acknowledgePromotion() { save.promotion = nil }

    public func addHistory(_ text: String, date: String) {
        guard save.replay == nil else { return }
        save.history.append(StoryHistoryEntry(date: date, text: text))
    }

    public func markHotspotSeen(_ id: String) { save.seenHotspots.insert(id) }

    /// « Modifier l'apparence » (h19): the name and the base stay.
    public func updateAppearance(_ appearance: CharacterAppearance) {
        var look = appearance
        look.presentation = save.player.appearance.presentation
        save.player.appearance = content.catalog.fitted(look, unlocked: save.unlocks)
    }

    public func updateAgreement(_ agreement: Agreement) { save.player.agreement = agreement }

    /// The chapter the player can play next (the current one, or the first unlocked unfinished one).
    public var nextPlayableChapter: StoryChapter? {
        content.campaign.chapters.first { c in
            c.status == .playable && save.unlocks.contains(c.id) && !save.completedChapters.contains(c.id)
        }
    }

    // MARK: - Player actions

    /// « Continuer »: the next line, the end of a pause, the reward or the office closed.
    @discardableResult
    public func advance() -> [StoryEvent] {
        switch mode {
        case .scene:
            autoAdvance = nil
            stage.titleCard = nil
            stage.notification = nil
            if let line = stage.line {
                guard line.choices.isEmpty, let scene else { return [] }
                return continueDialogue(from: scene.node(line.nodeID)?.next, in: scene)
            }
            if let after = save.position.afterPause, let scene {
                save.position.afterPause = nil
                return continueDialogue(from: after, in: scene)
            }
            pendingBeatsAfterPause = false
            return runBeats()
        case .result:
            save.promotion = nil
            save.position.showing = nil
            return nextStep()
        case .office:
            save.position.showing = nil
            return nextStep()
        default:
            return []
        }
    }

    /// The player answers.
    @discardableResult
    public func choose(_ choiceID: String) -> [StoryEvent] {
        guard case .scene = mode, let scene, let line = stage.line, line.choices.contains(where: { $0.id == choiceID }),
              let choice = scene.node(line.nodeID)?.choices?.first(where: { $0.id == choiceID }) else { return [] }
        var events: [StoryEvent] = []
        if save.replay == nil {
            save.choices[scene.id + "#" + line.nodeID] = choice.id
            if let sentence = choice.remember {
                let text = resolveText(sentence)
                var list = save.decisions[save.position.chapterID] ?? []
                if !list.contains(text) { list.append(text) }
                save.decisions[save.position.chapterID] = list
            }
        }
        if let effects = choice.effects, !effects.isEmpty, save.replay == nil {
            apply(effects)
            events.append(.effects(effects))
        }
        stage.line = nil
        if choice.silent == true {
            // The silence is an answer: no subtitle, the other person's close-up holds 2 s.
            if let shot = choice.shot {
                stage.shot = shot
                events.append(.camera(shot))
            }
            save.position.nodeID = nil
            save.position.afterPause = choice.next
            let seconds = choice.pause ?? 2
            autoAdvance = seconds
            events.append(.wait(seconds))
            if choice.next == nil {
                // Nothing after the silence: the scene goes on once it has been held.
                save.position.afterPause = nil
                pendingBeatsAfterPause = true
            }
            return events
        }
        if let shot = choice.shot {
            stage.shot = shot
            events.append(.camera(shot))
        }
        return events + continueDialogue(from: choice.next, in: scene)
    }

    /// The investigation of the current step is over (solved or not: the story goes on either way).
    @discardableResult
    public func caseFinished(_ caseID: String, solved: Bool, score: Int, found: Int, total: Int,
                             seconds: Int = 0, alibi: Bool = false) -> [StoryEvent] {
        guard case .awaitingCase(let waiting) = mode, waiting == caseID else { return [] }
        var record = save.cases[caseID] ?? StoryCaseRecord(caseID: caseID, solved: false, score: 0, found: 0, total: total, attempts: 0)
        record.attempts += 1
        record.solved = record.solved || solved
        record.score = max(record.score, score)
        record.found = max(record.found, found)
        record.total = total
        record.seconds = (record.seconds ?? 0) + max(0, seconds)
        record.alibi = alibi
        save.cases[caseID] = record
        save.stats.casesCompleted += 1
        if solved { save.stats.casesSolved += 1 } else { save.stats.mistakes += 1 }
        save.stats.cluesFound += found
        save.lastCaseSolved = solved
        save.position.awaitingCase = nil
        refreshCareer()
        return nextStep()
    }

    /// Plays lines and pauses without a choice until a choice, a notification or the end of the
    /// scene (« passer la scène »). Choices are never skipped: they are the player's.
    @discardableResult
    public func fastForward() -> [StoryEvent] {
        var events: [StoryEvent] = []
        let startScene = save.position.sceneID
        for _ in 0..<500 {
            guard case .scene = mode, save.position.sceneID == startScene else { break }
            if let line = stage.line, !line.choices.isEmpty { break }
            if stage.notification != nil { break }
            events += advance()
        }
        return events
    }

    // MARK: - Steps

    private func nextStep() -> [StoryEvent] { enterStep(save.position.stepIndex + 1) }

    private func enterStep(_ index: Int) -> [StoryEvent] {
        save.position.stepIndex = index
        save.position.sceneID = nil
        save.position.beatIndex = 0
        save.position.nodeID = nil
        save.position.showing = nil
        save.position.afterPause = nil
        pendingBeatsAfterPause = false
        stage.line = nil
        stage.notification = nil
        stage.titleCard = nil
        autoAdvance = nil
        guard let chapter else { mode = .finished; return [] }
        guard index < chapter.steps.count else { return completeChapter(chapter) }
        let step = chapter.steps[index]
        guard holds(step.condition) else { return enterStep(index + 1) }
        switch step.kind {
        case .scene:
            guard let id = step.scene, let scene = content.scene(id) else { return enterStep(index + 1) }
            return startScene(scene)
        case .investigation:
            // A replayed chapter only replays its scenes.
            guard let caseID = step.caseID, save.replay == nil else { return enterStep(index + 1) }
            save.position.awaitingCase = caseID
            mode = .awaitingCase(caseID)
            return [.startCase(caseID)]
        case .result:
            guard save.replay == nil else { return enterStep(index + 1) }
            if let reward = step.reward { grant(reward) }
            markFinished(chapter)
            refreshCareer()
            let result = makeResult(chapter)
            save.position.showing = "result"
            mode = .result(result)
            return [.result(result)]
        case .office:
            guard save.replay == nil else { return enterStep(index + 1) }
            save.position.showing = "office"
            mode = .office
            return [.office]
        }
    }

    private func completeChapter(_ chapter: StoryChapter) -> [StoryEvent] {
        if let replay = save.replay {
            save.replay = nil
            save.position = replay.returnPosition
            save.lastCaseSolved = replay.returnLastCaseSolved
            stage = StageState()
            mode = .idle
            return [.replayEnded]
        }
        markFinished(chapter)
        refreshCareer()
        mode = .chapterComplete(chapter.id)
        return [.chapterCompleted(chapter.id)]
    }

    /// The chapter counts as finished (career, next chapter unlocked). Idempotent.
    private func markFinished(_ chapter: StoryChapter) {
        if !save.completedChapters.contains(chapter.id) {
            save.completedChapters.append(chapter.id)
            save.stats.chaptersCompleted += 1
        }
        if let next = content.campaign.chapter(after: chapter.id) { save.unlocks.insert(next.id) }
    }

    private func makeResult(_ chapter: StoryChapter) -> StoryChapterResult {
        let caseIDs = chapter.steps.compactMap { $0.kind == .investigation ? $0.caseID : nil }
        let records = caseIDs.compactMap { save.cases[$0] }
        let investigations = records.filter { $0.alibi != true }
        let reward = chapter.steps.first { $0.kind == .result }?.reward
        return StoryChapterResult(chapterID: chapter.id,
                                  solved: records.allSatisfy(\.solved),
                                  casesSolved: investigations.filter(\.solved).count,
                                  cases: investigations.count,
                                  alibis: records.count - investigations.count,
                                  seconds: records.reduce(0) { $0 + ($1.seconds ?? 0) },
                                  decisions: save.decisions[chapter.id] ?? [],
                                  reward: reward,
                                  promotion: save.promotion,
                                  rank: save.rank,
                                  nextTier: content.campaign.tier(after: save.rank),
                                  solvedCount: solvedCount)
    }

    // MARK: - Scenes

    private func startScene(_ scene: StoryScene) -> [StoryEvent] {
        save.position.sceneID = scene.id
        save.position.beatIndex = 0
        save.position.nodeID = nil
        mode = .scene
        stage = StageState()
        stage.sceneID = scene.id
        stage.location = scene.location
        var events: [StoryEvent] = [.sceneStarted(scene: scene.id, location: scene.location)]
        if let ambience = content.location(scene.location)?.ambience {
            stage.ambience = ambience
            events.append(.ambience(ambience))
        }
        return events + runBeats()
    }

    /// Applies beats until one waits (a line, a pause, a card, a notification) or the scene ends.
    private func runBeats() -> [StoryEvent] {
        var events: [StoryEvent] = []
        while let scene, save.position.beatIndex < scene.beats.count {
            let beat = scene.beats[save.position.beatIndex]
            save.position.beatIndex += 1
            guard holds(beat.condition) else { continue }
            let (produced, blocking) = apply(beat, in: scene, silent: false)
            events += produced
            if blocking { return events }
        }
        guard let scene else { return events }
        if save.replay == nil { save.seenScenes.insert(scene.id) }
        events.append(.sceneEnded(scene.id))
        return events + nextStep()
    }

    /// One beat. `silent` (replaying a scene on resume): staging only, no consequence, no wait.
    private func apply(_ beat: SceneBeat, in scene: StoryScene, silent: Bool) -> (events: [StoryEvent], blocking: Bool) {
        let location = content.location(scene.location)
        func anchorState(_ id: String?, visible: Bool) -> ActorState? {
            guard let id, let a = location?.anchor(id) else { return nil }
            return ActorState(x: a.x, z: a.z, facing: a.facing, visible: visible, seated: a.seated ?? false, anchor: a.id, pose: a.seated == true ? "sit" : nil)
        }
        switch beat.kind {
        case .place:
            guard let actor = beat.actor, let state = anchorState(beat.anchor, visible: true) else { return ([], false) }
            stage.actors[actor] = state
            return ([.actorPlaced(actor)], false)
        case .enter:
            guard let actor = beat.actor, let state = anchorState(beat.anchor, visible: true) else { return ([], false) }
            stage.actors[actor] = state
            return ([.actorEntered(actor)], false)
        case .move:
            guard let actor = beat.actor, let state = anchorState(beat.anchor, visible: true) else { return ([], false) }
            stage.actors[actor] = state
            return ([.actorMoved(actor)], false)
        case .exit:
            guard let actor = beat.actor else { return ([], false) }
            if var state = anchorState(beat.anchor, visible: false) ?? stage.actors[actor] {
                state.visible = false
                stage.actors[actor] = state
            }
            return ([.actorLeft(actor)], false)
        case .face:
            guard let actor = beat.actor, let target = beat.target, var state = stage.actors[actor] else { return ([], false) }
            let point: (x: Double, z: Double)?
            if let other = stage.actors[target] { point = (other.x, other.z) }
            else if let prop = location?.prop(target) { point = (prop.x, prop.z) }
            else { point = nil }
            if let point {
                state.facing = (atan2(point.x - state.x, point.z - state.z) * 180 / .pi).rounded()
                stage.actors[actor] = state
            }
            return ([.actorFaced(actor, target: target)], false)
        case .animate:
            guard let actor = beat.actor, let animation = beat.animation else { return ([], false) }
            if var state = stage.actors[actor] {
                if animation == "sit" { state.seated = true }
                if animation == "stand" { state.seated = false }
                state.pose = animation
                stage.actors[actor] = state
            }
            return ([.animated(actor, animation: animation)], false)
        case .camera:
            guard let shot = beat.shot else { return ([], false) }
            stage.shot = shot
            return ([.camera(shot)], false)
        case .ambience:
            let sound = beat.sound ?? "none"
            stage.ambience = sound == "none" ? nil : sound
            return ([.ambience(sound)], false)
        case .sound:
            guard !silent, let sound = beat.sound else { return ([], false) }
            return ([.sound(sound)], false)
        case .effect:
            guard !silent, let effects = beat.effects, !effects.isEmpty else { return ([], false) }
            apply(effects)
            return ([.effects(effects)], false)
        case .dialogue:
            guard !silent else { return ([], false) }
            let events = continueDialogue(from: beat.node, in: scene, runOnEnd: false)
            return (events, stage.line != nil)
        case .wait:
            guard !silent else { return ([], false) }
            let seconds = beat.seconds ?? 1
            autoAdvance = seconds
            return ([.wait(seconds)], true)
        case .transition:
            guard !silent else { return ([], false) }
            let seconds = beat.seconds ?? 0.6
            autoAdvance = seconds
            return ([.transition(style: beat.style ?? "fade", seconds: seconds)], true)
        case .title:
            guard !silent else { return ([], false) }
            let seconds = beat.seconds ?? 2.5
            let text = resolveText(beat.text ?? "")
            stage.titleCard = text
            autoAdvance = seconds
            return ([.titleCard(text, seconds: seconds)], true)
        case .show:
            if let target = beat.target { stage.shownProps.insert(target); stage.removedProps.remove(target) }
            return ([], false)
        case .hide:
            if let target = beat.target { stage.removedProps.insert(target); stage.shownProps.remove(target) }
            return ([], false)
        case .notification:
            guard !silent else { return ([], false) }
            let notice = StoryNotice(title: resolveText(beat.title ?? ""), text: resolveText(beat.text ?? ""), app: beat.app ?? "messages")
            stage.notification = notice
            return ([.notification(notice), .sound("notification")], true)
        }
    }

    // MARK: - Dialogue

    /// Shows the first line from `nodeID` whose condition holds; at the end of the conversation,
    /// the scene goes on (unless called from the dialogue beat itself).
    private func continueDialogue(from nodeID: String?, in scene: StoryScene, runOnEnd: Bool = true) -> [StoryEvent] {
        var id = nodeID
        var events: [StoryEvent] = []
        var guardCount = 0
        while let current = id, let node = scene.node(current), guardCount < 200 {
            guardCount += 1
            guard holds(node.condition) else { id = node.next; continue }
            if let effects = node.effects, !effects.isEmpty {
                apply(effects)
                events.append(.effects(effects))
            }
            guard let line = resolve(node.id, in: scene) else { id = node.next; continue }
            stage.line = line
            save.position.nodeID = node.id
            if let shot = node.shot {
                stage.shot = shot
                events.append(.camera(shot))
            }
            if let animation = node.animation, node.speaker != "narrator" {
                if var state = stage.actors[node.speaker] { state.pose = animation; stage.actors[node.speaker] = state }
                events.append(.animated(node.speaker, animation: animation))
            }
            events.append(.line(line))
            return events
        }
        stage.line = nil
        save.position.nodeID = nil
        return runOnEnd ? events + runBeats() : events
    }

    private func resolve(_ nodeID: String, in scene: StoryScene) -> ResolvedLine? {
        guard let node = scene.node(nodeID) else { return nil }
        let name: String?
        switch node.speaker {
        case "narrator": name = nil
        case "player": name = "\(save.player.firstName) \(save.player.lastName)"
        default: name = content.npc(node.speaker)?.displayName
        }
        let role = node.speaker == "player" ? nil : content.npc(node.speaker)?.role
        let before = save.choices[scene.id + "#" + node.id]
        let choices = (node.choices ?? []).filter { holds($0.condition) }.map {
            ResolvedChoice(id: $0.id, text: resolveText($0.text), silent: $0.silent == true, chosenBefore: $0.id == before)
        }
        return ResolvedLine(nodeID: node.id, speaker: node.speaker, speakerName: name, speakerRole: role, text: resolveText(node.text),
                            emotion: node.emotion ?? "neutral", animation: node.animation, choices: choices, voice: node.voice)
    }

    public func resolveText(_ text: String) -> String {
        StoryText.resolve(text, player: save.player, rank: save.rank)
    }

    // MARK: - Consequences

    private func apply(_ effects: [StoryEffect]) {
        guard save.replay == nil else { return }
        for effect in effects {
            switch effect.kind {
            case .trust, .respect:
                guard let npc = effect.npc else { continue }
                var relation = save.relationships[npc] ?? StoryRelationship()
                if effect.kind == .trust { relation.trust = min(10, max(-10, relation.trust + (effect.amount ?? 1))) }
                else { relation.respect = min(10, max(-10, relation.respect + (effect.amount ?? 1))) }
                save.relationships[npc] = relation
            case .flag:
                if let flag = effect.flag { save.flags.insert(flag) }
            case .unlock:
                if let id = effect.id { save.unlocks.insert(id) }
            }
        }
    }

    private func grant(_ reward: StoryReward) {
        for id in reward.allUnlocks { save.unlocks.insert(id) }
        for flag in reward.flags ?? [] { save.flags.insert(flag) }
    }

    public func holds(_ condition: StoryCondition?) -> Bool {
        guard let c = condition else { return true }
        if let flag = c.flag, !save.flags.contains(flag) { return false }
        if let flag = c.notFlag, save.flags.contains(flag) { return false }
        if let solved = c.lastCaseSolved, save.lastCaseSolved != solved { return false }
        if let npc = c.npc, save.relationship(npc).trust < (c.atLeast ?? 0) { return false }
        return true
    }
}
