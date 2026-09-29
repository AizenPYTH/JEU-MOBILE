#if os(iOS)
import Foundation
import Observation
import SwiftUI
import StoryEngine
import StoryLibrary

/// The story's settings (h19). Stored per device; the story's save is separate.
enum StoryPreferences {
    enum SubtitleSize: String, CaseIterable { case small, medium, large }
    enum TextSpeed: String, CaseIterable { case slow, normal, instant }

    static let subtitleKey = "story.subtitleSize"
    static let speedKey = "story.textSpeed"
    static let autoKey = "story.autoAdvance"
    static let voiceKey = "story.voice"
    /// Settings of the former 3D stage (quality, depth of field, camera motion): removed with the
    /// 3D, still cleared by a reset.
    private static let retiredKeys = ["story.quality", "story.depthOfField", "story.reduceCameraMotion"]

    static var subtitleSize: SubtitleSize {
        get { SubtitleSize(rawValue: UserDefaults.standard.string(forKey: subtitleKey) ?? "") ?? .medium }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: subtitleKey) }
    }
    static var textSpeed: TextSpeed {
        get { TextSpeed(rawValue: UserDefaults.standard.string(forKey: speedKey) ?? "") ?? .normal }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: speedKey) }
    }
    static var autoAdvance: Bool {
        get { UserDefaults.standard.bool(forKey: autoKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoKey) }
    }
    static var voice: Bool {
        get { UserDefaults.standard.object(forKey: voiceKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: voiceKey) }
    }

    /// Seconds per character of the typewriter (0: instant).
    static var characterDelay: Double {
        switch textSpeed {
        case .slow: Trace.StoryMotion.typeSpeedSlow
        case .normal: Trace.StoryMotion.typeSpeedNormal
        case .instant: 0
        }
    }

    static func reset() {
        for key in [subtitleKey, speedKey, autoKey, voiceKey] + retiredKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

/// The story's save file (Application Support, written atomically, versioned by `StorySaveCoder`).
enum StorySaveStore {
    private static func url(_ name: String) -> URL? {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(name)
    }

    static var saveURL: URL? { url("story-save.json") }
    /// The portrait printed by the former 3D stage: no longer written, removed by a reset.
    private static var portraitURL: URL? { url("player_portrait.jpg") }

    static func load() -> StorySave? {
        guard let url = saveURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? StorySaveCoder.decode(data)
    }

    static func write(_ save: StorySave) {
        guard let url = saveURL, let data = try? StorySaveCoder.encode(save) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// « Réinitialiser l'histoire »: the story only (ENQUÊTES and ALIBI are kept).
    static func clear() {
        if let url = saveURL { try? FileManager.default.removeItem(at: url) }
        if let url = portraitURL { try? FileManager.default.removeItem(at: url) }
        SavedInvestigationStore.clear(.story)
    }
}

/// One line of the scene's JOURNAL.
struct JournalEntry: Identifiable, Hashable {
    let id: Int
    let speaker: String?
    let text: String
    /// An answer of the player (« ▸ »).
    let choice: Bool
    let player: Bool
}

/// Someone in the scene: the player or one of the BEN's people (initials on their print, no
/// portrait).
struct StoryParticipant: Identifiable, Hashable {
    let id: String
    let name: String
    let initials: String
    let role: String?
}

/// What the story mode shows, above the director's own state.
enum StoryScreen: Equatable {
    /// h04.
    case hub
    /// h05: identity, then the confirmation (the BEN card).
    case creator
    /// h11/h12: the director plays a scene (an interview report on the desk).
    case scene
    /// h15: the new file, before the briefing and the phone.
    case caseFolder(String)
    /// The phone (RootView plays the investigation).
    case phone(String)
    /// h16 → h17 → h18.
    case result
    /// h09 (`focus`: a hotspot to frame, from h18).
    case office(focus: String?)
    case profile
    case career
    case chapter(String)
    case settings
}

/// The story's coordinator: owns the director and the save, turns the director's events into
/// sound, haptics, transitions and screens (no 3D: the stage state only says who is present and
/// what is said), and persists after every action — quitting anywhere
/// resumes at the same place. Contains no story rule (StoryEngine does).
@MainActor
@Observable
final class StoryCoordinator {
    private(set) var content: StoryContent?
    private(set) var loadError: String?
    @ObservationIgnored private(set) var director: StoryDirector?
    /// Bumped after every change of the director (views read through it).
    private(set) var revision = 0
    var screen: StoryScreen = .hub
    /// The darkest wood over everything (fades between scenes and layers).
    private(set) var blackout: Double = 0
    private(set) var journal: [JournalEntry] = []
    /// A scripted notification on the player's phone (3 s).
    private(set) var banner: StoryNotice?
    /// The journal is open: the scene is paused.
    var journalOpen = false { didSet { if journalOpen { cancelTimers() } else { scheduleAutoAdvance() } } }
    /// AUTO pill.
    var auto: Bool = StoryPreferences.autoAdvance {
        didSet { StoryPreferences.autoAdvance = auto; scheduleAutoAdvance() }
    }
    /// The line on screen has been fully typed (the ▸ shows; AUTO may go on).
    private(set) var lineComplete = true
    /// Cases solved in ENQUÊTES (the career counts every mode).
    @ObservationIgnored private var externalSolved: Set<String> = []
    @ObservationIgnored private var timer: Task<Void, Never>?
    @ObservationIgnored private var bannerTask: Task<Void, Never>?
    @ObservationIgnored private var journalCounter = 0
    /// A fade in from black is already on its way.
    @ObservationIgnored private var revealing = false
    @ObservationIgnored private var pendingOfficeFocus: String?
    /// Called when the story needs the phone (RootView starts the investigation).
    @ObservationIgnored var onStartCase: (String) -> Void = { _ in }

    init() {}

    // MARK: Loading

    /// Loads the content and the save (once). Never a dead end: an error is shown by the hub.
    func load() {
        guard content == nil, loadError == nil else { return }
        do {
            let content = try StoryLibrary.load()
            self.content = content
            if let save = StorySaveStore.load() {
                makeDirector(content: content, save: save)
            }
        } catch {
            loadError = String(describing: error)
        }
        bump()
    }

    private func makeDirector(content: StoryContent, save: StorySave) {
        var save = save
        // A look that no longer fits the catalogue (a later version) is fitted, never refused.
        save.player.appearance = content.catalog.fitted(save.player.appearance, unlocked: save.unlocks)
        let d = StoryDirector(content: content, save: save)
        d.externalSolved = externalSolved
        director = d
    }

    /// The main mode's solved cases (from ProgressStore): shared career.
    func updateExternalSolved(_ ids: Set<String>) {
        externalSolved = ids
        director?.externalSolved = ids
        if director?.refreshCareer() != nil { persist() }
        bump()
    }

    // MARK: State for the views

    var hasInvestigator: Bool { director != nil }
    var save: StorySave? { _ = revision; return director?.save }
    var stage: StageState { _ = revision; return director?.stage ?? StageState() }
    var mode: DirectorMode { _ = revision; return director?.mode ?? .idle }
    var player: StoryPlayer? { save?.player }
    var catalog: CharacterCatalog? { content?.catalog }
    var officeLevel: Int { _ = revision; return director?.officeLevel ?? 1 }
    var canSkip: Bool { _ = revision; return director?.canSkipScene ?? false }
    var isReplaying: Bool { _ = revision; return director?.isReplaying ?? false }
    var solvedCount: Int { _ = revision; return director?.solvedCount ?? externalSolved.count }

    /// The chapter being played (or the next one to play).
    var currentChapter: StoryChapter? {
        _ = revision
        guard let director else { return content?.campaign.chapters.first }
        if case .chapterComplete = director.mode { return director.nextPlayableChapter ?? director.chapter }
        return director.chapter
    }

    /// « SCÈNE n / N » of the current chapter (scenes only).
    var sceneProgress: (index: Int, total: Int) {
        guard let chapter = currentChapter, let save else { return (0, 0) }
        let scenes = chapter.steps.enumerated().filter { $0.element.kind == .scene }
        let done = save.position.chapterID == chapter.id ? scenes.filter { $0.offset < save.position.stepIndex }.count : 0
        let finished = save.completedChapters.contains(chapter.id) && save.position.chapterID != chapter.id
        return (finished ? scenes.count : min(scenes.count, done + 1), scenes.count)
    }

    /// Nothing left to play (the next chapter is not written yet).
    var endOfContent: Bool {
        _ = revision
        guard let director else { return false }
        if case .chapterComplete = director.mode { return director.nextPlayableChapter == nil }
        if case .finished = director.mode { return true }
        return false
    }

    func resolve(_ text: String) -> String { director?.resolveText(text) ?? text }

    /// « BEN · BUREAU 312 · 21:06 »: the header of the scene's interview report.
    var scenePlace: String? {
        _ = revision
        guard let director, let id = director.stage.sceneID, let place = director.content.scene(id)?.place else { return nil }
        return director.resolveText(place)
    }

    /// The people of the scene (the player, then the BEN's people), in the data's order.
    var participants: [StoryParticipant] {
        _ = revision
        guard let director, let id = director.stage.sceneID, let scene = director.content.scene(id) else { return [] }
        let player = director.save.player
        return scene.participants.prefix(4).map { who in
            if who == "player" {
                return StoryParticipant(id: who, name: player.firstName + " " + player.lastName,
                                        initials: Self.initials(player.firstName, player.lastName), role: rankTitle())
            }
            if let npc = director.content.npc(who) {
                return StoryParticipant(id: who, name: npc.displayName, initials: Self.initials(npc.firstName, npc.lastName),
                                        role: npc.role)
            }
            return StoryParticipant(id: who, name: who, initials: String(who.prefix(2)).uppercased(), role: nil)
        }
    }

    /// « ÉM » from « Élise », « Morel ».
    nonisolated static func initials(_ first: String, _ last: String) -> String {
        (String(first.prefix(1)) + String(last.prefix(1))).uppercased()
    }

    func rankTitle(_ rank: StoryRank? = nil) -> String {
        guard let save else { return StoryText.rankTitle(rank ?? .enqueteur, form: .feminine) }
        return StoryText.rankTitle(rank ?? save.rank, form: StoryText.GrammaticalForm(save.player.agreement))
    }

    /// Seniority in game time: 3 months per chapter finished (« 6 mois », « 2 ans »).
    var seniority: String {
        guard let save, let content else { return "—" }
        let months = save.completedChapters.count * (content.campaign.monthsPerChapter ?? 3)
        if months == 0 { return "—" }
        if months < 12 { return L10n.f("story.seniority.months", months) }
        return L10n.f("story.seniority.years", months / 12)
    }

    // MARK: Creation

    /// « COMMENCER MA CARRIÈRE »: the investigator exists, chapter 1 starts (T-UI-3).
    func create(firstName: String, lastName: String, appearance: CharacterAppearance, agreement: Agreement) {
        guard let content, let first = content.campaign.chapters.first else { return }
        let now = Date()
        let seed = "\(firstName) \(lastName) \(now.timeIntervalSince1970)"
        let player = StoryPlayer(firstName: firstName, lastName: lastName, appearance: appearance, agreement: agreement,
                                 serviceNumber: StoryPlayer.serviceNumber(for: seed))
        let save = StorySave(player: player, firstChapter: first.id, createdAt: Self.day(now))
        makeDirector(content: content, save: save)
        director?.addHistory(L10n.t("story.history.assigned"), date: Self.day(now))
        persist()
        begin(fromBlack: 1.4)
        director.map { handle($0.startChapter(first.id)) }
    }

    func updateAgreement(_ agreement: Agreement) {
        director?.updateAgreement(agreement)
        persist()
        bump()
    }

    /// « Réinitialiser l'histoire » (held 1.6 s): the story only.
    func resetStory() {
        cancelTimers()
        AudioDirector.shared.stopAmbience()
        StorySaveStore.clear()
        director = nil
        journal = []
        screen = .hub
        bump()
    }

    // MARK: Playing

    /// [CONTINUER] (T-UI-2): wherever the save points.
    func continueStory() {
        guard let director else { return }
        switch director.mode {
        case .idle, .finished:
            begin(fromBlack: 0.7)
            handle(director.resume())
            if case .chapterComplete = director.mode { startNextChapter() }
        case .chapterComplete:
            startNextChapter()
        default:
            begin(fromBlack: 0.7)
            handle(director.resume())
        }
    }

    private func startNextChapter() {
        guard let director, let next = director.nextPlayableChapter else { screen = .hub; bump(); return }
        begin(fromBlack: 0.7)
        handle(director.startChapter(next.id))
    }

    /// h19 « Rejouer un chapitre ».
    func replay(_ chapterID: String) {
        guard let director else { return }
        begin(fromBlack: 0.7)
        handle(director.replayChapter(chapterID))
    }

    /// A tap on the scene: the whole line, then the next one.
    func tap() {
        guard let director, case .scene = director.mode, !journalOpen else { return }
        if !lineComplete {
            lineComplete = true
            bump()
            scheduleAutoAdvance()
            return
        }
        if director.stage.line?.choices.isEmpty == false { return }
        // A timed beat (a pause, a card) is not cut short by a tap: only lines are.
        if director.stage.line == nil, director.autoAdvance != nil { return }
        cancelTimers()
        handle(director.advance())
    }

    func choose(_ id: String) {
        guard let director else { return }
        cancelTimers()
        let choice = director.stage.line?.choices.first { $0.id == id }
        if let choice, !choice.silent {
            appendJournal(speaker: director.save.player.firstName + " " + director.save.player.lastName, text: choice.text, choice: true, player: true)
        }
        Haptics.selection()
        handle(director.choose(id))
    }

    /// « PASSER » (a scene already seen).
    func skipScene() {
        guard let director, director.canSkipScene else { return }
        cancelTimers()
        handle(director.skipScene())
    }

    /// The typewriter finished the line.
    func lineDidComplete() {
        guard !lineComplete else { return }
        lineComplete = true
        bump()
        scheduleAutoAdvance()
    }

    /// h15 [OUVRIR LE DOSSIER] → the briefing and the phone (RootView).
    func openCaseFolder(_ caseID: String) {
        screen = .phone(caseID)
        bump()
        onStartCase(caseID)
    }

    /// The investigation is over, its report filed (T-SIG-2: black, the BEN's ambience, the scene).
    func caseFinished(_ caseID: String, solved: Bool, score: Int, found: Int, total: Int, seconds: Int, alibi: Bool) {
        guard let director else { return }
        SavedInvestigationStore.clear(.story)
        let before = director.save.rank
        begin(fromBlack: 0.7)
        handle(director.caseFinished(caseID, solved: solved, score: score, found: found, total: total, seconds: seconds, alibi: alibi))
        if director.save.rank > before { recordPromotion(director.save.rank) }
        persist()
    }

    /// The phone was left (paused): back to the hub; CONTINUER resumes the investigation.
    func leftPhone() {
        screen = .hub
        bump()
    }

    /// h16 → h17 → h18 done: the chapter goes on. `officeFocus`: « Voir dans mon bureau » — the
    /// office (h09) opens on that object when the chapter reaches it.
    func finishResult(officeFocus: String? = nil) {
        guard let director else { return }
        pendingOfficeFocus = officeFocus
        begin(fromBlack: 0.7)
        handle(director.advance())
    }

    func closeOffice() {
        guard let director else { screen = .hub; return }
        if case .office = director.mode {
            begin(fromBlack: 0.5)
            handle(director.advance())
        } else {
            screen = .hub
            bump()
        }
    }

    func markHotspotSeen(_ id: String) {
        director?.markHotspotSeen(id)
        persist()
        bump()
    }

    /// Leaves a scene for the hub (the position is kept).
    func pauseToHub() {
        cancelTimers()
        AudioDirector.shared.stopAmbience()
        persist()
        screen = .hub
        bump()
    }

    // MARK: Events

    private func handle(_ events: [StoryEvent]) {
        guard let director else { return }
        for event in events {
            switch event {
            case .sceneStarted:
                journal = []
                screen = .scene
                // A scene that follows a fade in the same chapter comes back from black.
                if blackout > 0 && !revealing { begin(fromBlack: 0.5) }
                if let ambience = director.stage.ambience { loopAmbience(ambience) }
            case .ambience(let name):
                if name == "none" { AudioDirector.shared.stopAmbience() } else { loopAmbience(name) }
            case .sound(let name):
                AudioDirector.shared.play(name, volume: 0.8)
            case .line(let line):
                lineComplete = StoryPreferences.characterDelay == 0
                appendJournal(speaker: line.speakerName, text: line.text, choice: false, player: line.speaker == "player")
                if StoryPreferences.voice, let voice = line.voice { AudioDirector.shared.play(voice) }
            case .notification(let notice):
                banner = notice
                Haptics.light()
                bannerTask?.cancel()
                bannerTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(3))
                    guard !Task.isCancelled else { return }
                    self?.banner = nil
                    self?.tapThroughNotification()
                }
            case .transition(let style, let seconds):
                if style == "fade" { fade(seconds: seconds) }
            case .startCase(let caseID):
                AudioDirector.shared.stopAmbience(fadeOut: 0.6)
                if SavedInvestigationStore.load(.story).map({ $0.snapshot.caseID == caseID }) == true {
                    // An investigation already on the phone: straight back to it.
                    openCaseFolder(caseID)
                } else {
                    screen = .caseFolder(caseID)
                }
            case .result(let result):
                AudioDirector.shared.stopAmbience(fadeOut: 0.6)
                // A rank reached at the chapter's end: in the history now (once), shown by h17.
                if let promotion = result.promotion { recordPromotion(promotion.to) }
                screen = .result
            case .office:
                screen = .office(focus: pendingOfficeFocus)
                pendingOfficeFocus = nil
            case .chapterCompleted(let id):
                AudioDirector.shared.stopAmbience()
                let number = director.content.campaign.chapter(id)?.number ?? 0
                director.addHistory(L10n.f("story.history.chapter", dossierNumber(number)), date: Self.day(.now))
                screen = .hub
            case .replayEnded:
                AudioDirector.shared.stopAmbience()
                screen = .hub
            case .sceneEnded, .actorPlaced, .actorEntered, .actorMoved, .actorLeft, .actorFaced, .animated, .camera,
                 .wait, .titleCard, .effects:
                break
            }
        }
        persist()
        bump()
        scheduleAutoAdvance()
    }

    private func tapThroughNotification() {
        guard let director, director.stage.notification != nil else { return }
        handle(director.advance())
    }

    /// Timed beats end by themselves; with AUTO, lines too (1.2 s + 45 ms per character).
    private func scheduleAutoAdvance() {
        timer?.cancel()
        guard let director, case .scene = director.mode, !journalOpen else { return }
        let delay: Double
        if let line = director.stage.line {
            guard auto, line.choices.isEmpty, lineComplete else { return }
            delay = Trace.StoryMotion.autoDelay(line.text)
        } else if director.stage.notification != nil {
            return
        } else if let seconds = director.autoAdvance {
            delay = seconds
        } else {
            return
        }
        timer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self, let director = self.director else { return }
            self.handle(director.advance())
        }
    }

    private func cancelTimers() {
        timer?.cancel()
        timer = nil
    }

    // MARK: Presentation helpers

    /// Starts on black and fades in (T-UI-2 / T-UI-3 / T-SIG-2).
    private func begin(fromBlack seconds: Double) {
        blackout = 1
        revealing = true
        let reduce = UIAccessibility.isReduceMotionEnabled || UserDefaults.standard.bool(forKey: Preferences.reduceMotionKey)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(reduce ? 0.1 : 0.3))
            self?.revealing = false
            withAnimation(.easeOut(duration: reduce ? 0.2 : seconds)) { self?.blackout = 0 }
        }
    }

    private func fade(seconds: Double) {
        let reduce = UIAccessibility.isReduceMotionEnabled || UserDefaults.standard.bool(forKey: Preferences.reduceMotionKey)
        withAnimation(.easeIn(duration: reduce ? 0.2 : min(0.4, seconds / 2))) { blackout = 1 }
    }

    /// Ambience names of the story (« ben_hvac »…); a missing file is silently ignored.
    private func loopAmbience(_ name: String) {
        AudioDirector.shared.stopAmbience(keeping: [name], fadeOut: 0.8)
        AudioDirector.shared.loop(name, volume: 0.35, fadeIn: 0.8)
    }

    private func appendJournal(speaker: String?, text: String, choice: Bool, player: Bool) {
        journalCounter += 1
        journal.append(JournalEntry(id: journalCounter, speaker: speaker, text: text, choice: choice, player: player))
    }

    /// « Avancement : Inspectrice » in the history, once per rank.
    private func recordPromotion(_ rank: StoryRank) {
        guard let director else { return }
        let text = L10n.f("story.history.promotion", rankTitle(rank))
        guard !director.save.history.contains(where: { $0.text == text }) else { return }
        director.addHistory(text, date: Self.day(.now))
        persist()
    }

    /// Acknowledged promotion (h17 shown).
    func acknowledgePromotion() {
        director?.acknowledgePromotion()
        persist()
        bump()
    }

    private func persist() {
        guard let director else { return }
        StorySaveStore.write(director.save)
    }

    private func bump() { revision &+= 1 }

    static func day(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// « 27 sept. 2026 » from a history date.
    static func shownDay(_ day: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: day) else { return day }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}
#endif
