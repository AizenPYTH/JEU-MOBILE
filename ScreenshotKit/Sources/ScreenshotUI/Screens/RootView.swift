#if os(iOS)
import SwiftUI
import CaseEngine
import CaseLibrary
import StoryEngine

/// Launch (01): the launch screen does the real start-up work, then fades into the game.
public struct RootView: View {
    @State private var loader = LaunchLoader()
    @State private var boot: BootData?

    public init() {}

    public var body: some View {
        ZStack {
            Trace.Colors.bg.ignoresSafeArea()
            if let boot {
                GameRoot(boot: boot, onRetry: retryLoading)
                    .transition(.opacity)
            } else {
                LoadingScreen(loader: loader) { data in
                    withAnimation(.easeInOut(duration: 0.35)) { boot = data }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }

    /// « Réessayer » on the loading error card: the launch work runs again (saves are untouched).
    private func retryLoading() {
        loader = LaunchLoader()
        withAnimation(.easeInOut(duration: 0.2)) { boot = nil }
    }
}

/// The game's flow (UX V3 §4, §7).
///
/// First launch: 00 Première impression → Qui enquête ? → Dossier #001 → Téléphone. After the
/// first report of #001: Affectation (12) → Bureau. Later launches: the Bureau directly (its
/// CaseCard offers « Reprendre » when an investigation is in progress). In a case: Dossier →
/// ouverture → Téléphone ⇄ Carnet → Conclusion → Vérification + Rapport → Bureau.
struct GameRoot: View {
    enum Stage {
        /// 00 · first launch only.
        case firstImpression
        /// Who investigates (first launch).
        case whoInvestigates
        /// 01 · the Bureau: the modes' segmented control (Enquêtes · Alibi · Histoire).
        case home
        /// HISTOIRE (hub, creator, scenes, chapter results, office…).
        case story
        /// A story case's briefing (its own save slot; back to the story).
        case storyIntro(CaseFile)
        case cases
        case archive
        case profile
        case settings
        /// 02 · the case file.
        case intro(CaseFile)
        /// ALIBI: one check's mini-file (the list is the Bureau's Alibi segment).
        case alibiIntro(CaseFile)
        /// From the case file to the phone: the sealed bag, the zoom, the lock screen.
        case opening(GameSession)
        case playing(GameSession)
        /// Verification, then the closing report.
        case result(Play)
        /// 12 · official assignment to the BEN (once, after #001).
        case assignment(solved: Bool)
        /// « Voir le rapport » of a played case.
        case archived(CaseFile, Attempt)
    }

    /// A new case asked for while another one is in progress (« Commencer quand même ? »).
    struct PendingStart: Identifiable {
        let file: CaseFile
        let challenge: Challenge
        /// Number of the case whose investigation would be abandoned.
        let inProgress: Int

        var id: String { file.id }
    }

    /// A finished investigation on its way through the result screens.
    struct Play {
        let session: GameSession
        let verdict: Verdict
        let attemptID: UUID
        var revealed = false
        /// Played in « Temps détendu ».
        var relaxed = false
    }

    @State private var stage: Stage = .home
    /// Where the settings return to.
    @State private var settingsReturn: Stage = .profile
    /// Where « Voir le rapport » returns to.
    @State private var archivedReturn: DeskTab = .bureau
    @State private var attempts: [Attempt] = []
    /// The investigation the player left, if any ("Reprendre l'enquête").
    @State private var savedGame: SavedInvestigation?
    @State private var identity: PlayerIdentity = PlayerStore.identity
    @State private var assigned: Bool = PlayerStore.isAssigned
    /// « Classer quand même » was chosen on a report of #001.
    @State private var filedAnyway = false
    /// Starting a case while another one is in progress: asked first.
    @State private var replaceAsk: PendingStart?
    /// « Commencer quand même »: the case starts once the sheet has gone.
    @State private var replaceConfirmed: PendingStart?
    /// The case just classified as solved: its CaseCard shows on the Bureau and the RÉSOLU stamp
    /// falls on it (§6-12). Cleared once the player leaves the Bureau.
    @State private var justFiled: String?
    /// The Bureau's mode segment, remembered (§6-01).
    @AppStorage(Preferences.deskModeKey) private var deskMode: DeskMode = .investigations
    /// The story mode (its own save).
    @State private var story = StoryCoordinator()
    @AppStorage(Preferences.reduceMotionKey) private var reduceMotion = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private let cases: [CaseFile]
    private let rules: GameRules?
    private let loadError: String?
    private let onRetry: () -> Void

    /// Everything was loaded by the launch screen (`LaunchLoader`): fonts, saves, rules, cases.
    init(boot: BootData, onRetry: @escaping () -> Void = {}) {
        _attempts = State(initialValue: boot.attempts)
        _savedGame = State(initialValue: boot.savedGame)
        cases = boot.cases
        rules = boot.rules
        loadError = boot.loadError
        self.onRetry = onRetry
        let inProgress = boot.savedGame.map { saved in boot.cases.contains { $0.id == saved.snapshot.caseID } } ?? false
        let firstID = (boot.cases.first { $0.number == 1 } ?? boot.cases.first)?.id
        let first: Stage
        if inProgress {
            // The Bureau's CaseCard offers « Reprendre ».
            first = .home
        } else if !PlayerStore.isAssigned, let firstID,
                  PlayerStore.assignmentDue(attempts: boot.attempts, firstCaseID: firstID, filedAnyway: false) {
            // #001 was concluded but the game was left before its report was filed: screen 12 is owed.
            first = .assignment(solved: boot.attempts.contains { $0.caseID == firstID && $0.solved })
        } else if !PlayerStore.isAssigned && !PlayerStore.hasChosen {
            // A brand-new player: 00 · Première impression.
            first = .firstImpression
        } else {
            first = .home
        }
        _stage = State(initialValue: first)
    }

    private var noMotion: Bool { reduceMotion || systemReduceMotion }

    var body: some View {
        ZStack {
            Trace.Colors.bg.ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
        .animation(noMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper, value: stageKey)
        .onChange(of: stageKey) { _, key in
            // The stamp belongs to the return to the Bureau (through the assignment, once).
            if key != "home" && key != "assignment" { justFiled = nil }
        }
        .sheet(item: $replaceAsk, onDismiss: {
            guard let pending = replaceConfirmed else { return }
            replaceConfirmed = nil
            begin(pending.file, challenge: pending.challenge)
        }) { pending in
            PaperConfirmSheet(title: L10n.t("start.replaceTitle"),
                              message: L10n.f("start.replaceMessage", shownNumber(pending.inProgress)),
                              confirm: L10n.t("start.replaceConfirm"),
                              confirmID: "start.confirmReplace",
                              destructive: true,
                              cancel: L10n.t("start.replaceCancel"),
                              cancelID: "start.cancelReplace",
                              onConfirm: {
                                  replaceConfirmed = pending
                                  replaceAsk = nil
                              },
                              onCancel: { replaceAsk = nil })
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationBackground(Trace.Colors.surface)
        }
    }

    /// Screens slide in (fade + 24 pt); with reduced motion, they only fade.
    private var push: AnyTransition {
        noMotion ? .opacity : .opacity.combined(with: .offset(x: 24))
    }

    @ViewBuilder
    private var content: some View {
        if let loadError {
            DamagedFileView(detail: loadError, onRetry: onRetry)
        } else {
            switch stage {
            case .firstImpression:
                FirstImpressionView(onStart: beginFirstCase)
                    .transition(.opacity)
            case .whoInvestigates:
                WhoInvestigatesScreen(initial: identity, allowsAppearance: false,
                                      onContinue: { chosen in
                                          PlayerStore.identity = chosen
                                          identity = chosen
                                          openFirstCase()
                                      },
                                      onBack: { stage = .firstImpression })
                    .transition(push)
            case .home:
                BureauView(identity: identity,
                           mode: $deskMode,
                           modesUnlocked: assigned,
                           firstNumber: firstCase?.number ?? 1,
                           cases: mainCases,
                           progress: progress,
                           attempts: attempts,
                           resumable: mainResumable,
                           durations: mainDurations,
                           justFiled: justFiled,
                           alibiCases: alibiCases,
                           alibiInProgressID: resumable?.file.isAlibi == true ? resumable?.file.id : nil,
                           story: storySummary,
                           onOpen: { stage = .intro($0) },
                           onResume: resumeSaved,
                           onReport: openReport,
                           onAlibi: { stage = .alibiIntro($0) },
                           onStory: openStory,
                           onStoryVisible: {
                               story.load()
                               refreshStory()
                           },
                           onProfile: { selectTab(.investigator) },
                           onTab: selectTab)
                    .transition(.opacity)
            case .story:
                StoryRootView(story: story, caseInfo: storyCaseInfo, onExit: {
                    deskMode = .story
                    goHome()
                })
                .transition(.opacity)
            case .storyIntro(let file):
                DossierView(caseFile: file,
                            rules: rules,
                            durations: durations(of: file),
                            unlocked: [.detective],
                            levels: [:],
                            saved: nil,
                            attempts: [],
                            archiveOpen: false,
                            onStart: { _ in beginStory(file) },
                            onResume: {},
                            onClose: { stage = .story },
                            backTitle: L10n.t("desk.mode.story"))
                    .environment(\.caseNumber, file.number)
                    .transition(push)
            case .alibiIntro(let file):
                AlibiBriefingView(caseFile: file,
                                  durationSeconds: durations(of: file)[.detective] ?? file.durationSeconds,
                                  inProgress: resumable?.file.id == file.id,
                                  onStart: { start(file, challenge: .detective) },
                                  onResume: resumeSaved,
                                  onClose: {
                                      deskMode = .alibi
                                      goHome()
                                  })
                    .environment(\.caseNumber, file.number)
                    .transition(push)
            case .cases, .archive:
                ArchivesView(cases: mainCases, progress: progress, attempts: attempts, savedCaseID: resumable?.file.id,
                             onOpen: { stage = .intro($0) }, onTab: selectTab)
                    .transition(.opacity)
            case .profile:
                InvestigatorView(attempts: attempts, cases: mainCases, identity: identity, assigned: assigned,
                                 onChangeIdentity: { chosen in
                                     PlayerStore.identity = chosen
                                     identity = chosen
                                 },
                                 onSettings: { openSettings(from: .profile) },
                                 onTab: selectTab)
                    .transition(.opacity)
            case .settings:
                GameSettingsView(onBack: { stage = settingsReturn })
                    .transition(push)
            case .intro(let file):
                DossierView(caseFile: file,
                            rules: rules,
                            durations: durations(of: file),
                            unlocked: Set(Challenge.allCases.filter { level in
                                rules?.isUnlocked(level, solvedAt: solvedLevels(of: file)) ?? true
                            }),
                            levels: ProgressStore.levels(of: file.id, in: attempts),
                            saved: resumable?.file.id == file.id ? resumable?.saved : nil,
                            attempts: attempts.filter { $0.caseID == file.id },
                            archiveOpen: progress[file.id]?.archiveOpen == true,
                            onStart: { start(file, challenge: $0) },
                            onResume: resumeSaved,
                            onClose: leaveBriefing)
                    .environment(\.caseNumber, file.number)
                    .transition(push)
            case .opening(let session):
                CaseOpeningView(session: session, onDone: { handOver(session) })
                    .environment(\.caseNumber, session.caseFile.number)
                    .transition(.opacity)
            case .playing(let session):
                PlayingView(session: session, onQuit: { quit(session) })
                    .environment(\.caseNumber, session.caseFile.number)
                    .transition(.opacity)
            case .result(let play) where play.session.caseFile.isAlibi:
                AlibiResultView(verdict: play.verdict, caseFile: play.session.caseFile, revealed: play.revealed,
                                onFile: { fileAway(play, anyway: false) },
                                onRetry: { retry(play) },
                                onReveal: { reveal(play) })
                    .id(play.revealed)
                    .environment(\.caseNumber, play.session.caseFile.number)
                    .transition(.opacity)
            case .result(let play):
                ResultView(verdict: play.verdict, caseFile: play.session.caseFile, names: names(play.session),
                           revealed: play.revealed,
                           relaxed: play.relaxed,
                           culprit: contact(play.session, play.verdict.culprit),
                           accused: contact(play.session, play.verdict.accused),
                           onFile: { fileAway(play, anyway: false) },
                           onRetry: { retry(play) },
                           onFileAnyway: { fileAway(play, anyway: true) },
                           onRevealRequested: { reveal(play) },
                           connections: play.session.game.connections.count)
                    .id(play.revealed)
                    .environment(\.caseNumber, play.session.caseFile.number)
                    .transition(.opacity)
            case .assignment(let solved):
                AssignmentView(identity: identity, rank: rank, solved: solved,
                               remainingCases: max(0, mainCases.count - 1),
                               onDesk: {
                                   PlayerStore.isAssigned = true
                                   assigned = true
                                   goHome()
                               })
                    .transition(.opacity)
            case .archived(let file, let attempt):
                ArchivedCaseView(caseFile: file, attempt: attempt, onClose: { selectTab(archivedReturn) },
                                 backTitle: L10n.t(archivedReturn == .bureau ? "tab.bureau" : "tab.archives"))
                    .environment(\.caseNumber, file.number)
                    .transition(push)
            }
        }
    }

    private var progress: [String: CaseProgress] { ProgressStore.summary(of: attempts) }

    /// The investigations (main mode) and the ALIBI checks.
    private var mainCases: [CaseFile] { cases.filter(\.isMainInvestigation) }
    private var alibiCases: [CaseFile] { cases.filter(\.isAlibi) }

    /// Seconds of each main case at its intended level (« Temps détendu » included).
    private var mainDurations: [String: Int] {
        Dictionary(uniqueKeysWithValues: mainCases.map { ($0.id, durations(of: $0)[.detective] ?? $0.durationSeconds) })
    }

    /// Rank from the number of investigations solved (ENQUÊTEUR → INSPECTEUR → SENIOR → EXPÉRIMENTÉ).
    private var rank: Rank {
        Rank.forSolved(mainCases.filter { progress[$0.id]?.solved == true }.count)
    }

    private func selectTab(_ tab: DeskTab) {
        attempts = ProgressStore.attempts()
        savedGame = SavedInvestigationStore.load()
        switch tab {
        case .bureau:
            refreshStory()
            stage = .home
        case .archives: stage = .cases
        case .investigator: stage = .profile
        }
    }

    private func openSettings(from origin: Stage) {
        settingsReturn = origin
        stage = .settings
    }

    private var firstCase: CaseFile? { mainCases.first { $0.number == 1 } ?? mainCases.first }

    private var stageKey: String {
        switch stage {
        case .firstImpression: "firstImpression"
        case .whoInvestigates: "who"
        case .home: "home"
        case .story: "story"
        case .storyIntro(let f): "storyIntro-\(f.id)"
        case .cases: "cases"
        case .archive: "archive"
        case .profile: "profile"
        case .settings: "settings"
        case .intro(let f): "intro-\(f.id)"
        case .alibiIntro(let f): "alibiIntro-\(f.id)"
        case .opening: "opening"
        case .playing: "playing"
        case .result(let p): "result-\(p.revealed)"
        case .assignment: "assignment"
        case .archived(_, let a): "archived-\(a.id)"
        }
    }

    /// 00 [Commencer] → Qui enquête ? (if nobody chose yet) → Dossier #001.
    private func beginFirstCase() {
        if PlayerStore.hasChosen { openFirstCase() } else { stage = .whoInvestigates }
    }

    private func openFirstCase() {
        if let firstCase { stage = .intro(firstCase) } else { goHome() }
    }

    /// « ‹ Bureau » from a case file that was not started.
    private func leaveBriefing() {
        deskMode = .investigations
        goHome()
    }

    /// 01 · the Bureau, with fresh progress.
    private func goHome() {
        attempts = ProgressStore.attempts()
        savedGame = SavedInvestigationStore.load()
        refreshStory()
        stage = .home
    }

    /// « Voir le rapport » on a solved CaseCard: the report of its last solved attempt.
    private func openReport(_ file: CaseFile) {
        guard let attempt = ProgressStore.reportAttempt(of: file.id, in: attempts) else {
            stage = .intro(file)
            return
        }
        archivedReturn = .bureau
        stage = .archived(file, attempt)
    }

    /// The saved investigation when it is a main-mode case (the Bureau's CaseCard).
    private var mainResumable: (saved: SavedInvestigation, file: CaseFile)? {
        resumable.flatMap { $0.file.isMainInvestigation ? $0 : nil }
    }

    /// The saved investigation and its case, when it belongs to a case of this version.
    private var resumable: (saved: SavedInvestigation, file: CaseFile)? {
        guard let savedGame, let file = cases.first(where: { $0.id == savedGame.snapshot.caseID }) else { return nil }
        return (savedGame, file)
    }

    /// "Reprendre l'enquête": back to the same screen, same time, same pieces.
    private func resumeSaved() {
        guard let rules, let resumable,
              let session = GameSession(restoring: resumable.saved, caseFile: resumable.file, rules: rules,
                                        onFinish: { finished($0) }) else {
            // A save that cannot be read again: never a dead end.
            SavedInvestigationStore.clear()
            savedGame = nil
            goHome()
            return
        }
        session.begin()
        stage = .playing(session)
    }

    private func names(_ session: GameSession) -> [SuspectID: String] {
        Dictionary(uniqueKeysWithValues: session.caseFile.suspects.map { ($0.id, session.game.name(of: $0.contact)) })
    }

    /// The contact behind a suspect (the culprit, or whoever was accused).
    private func contact(_ session: GameSession, _ id: SuspectID) -> Contact? {
        session.game.index.suspect(id).flatMap { session.game.contact($0.contact) }
    }

    /// Duration of a case at each level (« Temps détendu » included).
    private func durations(of file: CaseFile) -> [Challenge: Int] {
        var result: [Challenge: Int] = [:]
        for level in Challenge.allCases {
            let base = rules.map { file.duration(for: level, rules: $0) } ?? file.durationSeconds
            result[level] = Self.relaxed(base)
        }
        return result
    }

    private static func relaxed(_ seconds: Int) -> Int {
        Preferences.relaxedTime ? Int((Double(seconds) * Preferences.relaxedTimeFactor).rounded()) : seconds
    }

    /// Levels at which a case was already solved (ranked or not).
    private func solvedLevels(of file: CaseFile) -> Set<Challenge> {
        Set(attempts.filter { $0.caseID == file.id && $0.solved }.map(\.level))
    }

    /// A new investigation at a challenge level (replaces any saved one). Another case in progress
    /// is never dropped silently: the player confirms first. The same case asks on its own briefing.
    private func start(_ original: CaseFile, challenge: Challenge) {
        if let resumable, resumable.file.id != original.id {
            replaceAsk = PendingStart(file: original, challenge: challenge, inProgress: resumable.file.number)
            return
        }
        begin(original, challenge: challenge)
    }

    private func begin(_ original: CaseFile, challenge: Challenge) {
        guard let session = makeSession(original, challenge: challenge) else { return }
        SavedInvestigationStore.clear()
        savedGame = nil
        // The clock starts when the phone is in the player's hands.
        stage = .opening(session)
    }

    private func makeSession(_ original: CaseFile, challenge: Challenge, slot: SaveSlot = .main) -> GameSession? {
        guard let rules else { return nil }
        var played = original.configured(for: challenge, rules: rules)
        played.durationSeconds = Self.relaxed(played.durationSeconds)
        played = UITestHooks.adjusted(played)
        return GameSession(caseFile: played, rules: rules, challenge: challenge, slot: slot) { finished($0) }
    }

    // MARK: Story

    /// The Histoire card's button: the creator the first time, the hub after.
    private func openStory() {
        story.load()
        refreshStory()
        story.onStartCase = { startStoryCase($0) }
        if isPhoneScreen(story.screen) { story.screen = .hub }
        stage = .story
    }

    private func isPhoneScreen(_ screen: StoryScreen) -> Bool {
        if case .phone = screen { return true }
        return false
    }

    /// The career counts every investigation solved in ENQUÊTES.
    private func refreshStory() {
        let solved = Set(attempts.filter(\.solved).map(\.caseID)).intersection(Set(mainCases.map(\.id)))
        story.updateExternalSolved(solved)
    }

    /// h15 [OUVRIR LE DOSSIER]: the briefing, or straight back to the phone left in the story.
    private func startStoryCase(_ caseID: String) {
        guard let rules, let file = cases.first(where: { $0.id == caseID }) else {
            story.leftPhone()
            return
        }
        if let saved = SavedInvestigationStore.load(.story), saved.snapshot.caseID == caseID,
           let session = GameSession(restoring: saved, caseFile: file, rules: rules, slot: .story, onFinish: { finished($0) }) {
            session.begin()
            stage = .playing(session)
            return
        }
        stage = .storyIntro(file)
    }

    private func beginStory(_ file: CaseFile) {
        guard let session = makeSession(file, challenge: .detective, slot: .story) else { return }
        SavedInvestigationStore.clear(.story)
        stage = .opening(session)
    }

    /// « N° 001 » for an ENQUÊTES case played in a chapter, « N° C02-A » for a case of the story.
    private func storyCaseInfo(_ caseID: String) -> (title: String, label: String, chapter: Int)? {
        guard let file = cases.first(where: { $0.id == caseID }) else { return nil }
        let chapters = story.content?.campaign.chapters ?? []
        let chapter = chapters.first { $0.steps.contains { $0.caseID == caseID } }
        let number = chapter?.number ?? 1
        let letterIndex = chapter.map { c in c.steps.filter { $0.kind == .investigation }.firstIndex { $0.caseID == caseID } ?? 0 } ?? 0
        let letter = String(UnicodeScalar(UInt8(65 + min(letterIndex, 25))))
        let label = file.isStory ? "N° C\(dossierNumber(number).suffix(2))-\(letter)" : "N° \(shownNumber(file.number))"
        return (file.title, label, number)
    }

    /// « PREMIÈRE AFFECTATION » → « Première affectation ».
    static func sentenceCase(_ title: String) -> String {
        let lower = title.lowercased()
        return lower.prefix(1).uppercased() + lower.dropFirst()
    }

    /// The Bureau's Histoire card: the chapter in progress and its progress.
    private var storySummary: StoryDeskSummary {
        let chapter = story.currentChapter
        let scenes = story.sceneProgress
        return StoryDeskSummary(hasInvestigator: story.hasInvestigator,
                                chapterLine: chapter.map { L10n.f("mode.story.chapter", $0.number, Self.sentenceCase($0.title)) },
                                progress: scenes.total > 0 ? Double(max(0, scenes.index - 1)) / Double(scenes.total) : 0)
    }

    /// End of the opening: the phone just unlocked is the one the player now holds.
    private func handOver(_ session: GameSession) {
        session.begin()
        stage = .playing(session)
    }

    /// Leaving the phone (« Mettre en pause »): the investigation is saved. Back to the Bureau, on
    /// the mode it belongs to (its card offers to resume it).
    private func quit(_ session: GameSession) {
        session.pause()
        if session.slot == .story {
            story.leftPhone()
            stage = .story
            return
        }
        deskMode = session.caseFile.isAlibi ? .alibi : .investigations
        goHome()
    }

    private func finished(_ verdict: Verdict) {
        guard case .playing(let session) = stage else { return }
        if session.slot == .story, !session.caseFile.isMainInvestigation, !session.caseFile.isAlibi {
            // A case of the story only: its result belongs to the story's save.
            stage = .result(Play(session: session, verdict: verdict, attemptID: UUID()))
            return
        }
        let attempt = Attempt(caseID: session.caseFile.id, date: .now, score: verdict.score, solved: verdict.isCorrect,
                              ranked: true, found: verdict.foundCount, total: verdict.totalCount,
                              hintsUsed: verdict.hintsUsed, challenge: session.game.challenge,
                              timeUsed: session.caseFile.durationSeconds - verdict.remainingSeconds)
        ProgressStore.record(attempt)
        attempts = ProgressStore.attempts()
        savedGame = nil
        // The tutorial belongs to the first play of #001 only, even if some bubbles never showed.
        if session.caseFile.number == 1 { TutorialCoach.markSeen() }
        // « Temps détendu » is read from the duration the case was played with (the setting may
        // have changed while it was paused).
        let original = cases.first { $0.id == session.caseFile.id }
        let normal = original.flatMap { file in rules.map { file.duration(for: session.game.challenge, rules: $0) } }
        let relaxed = session.caseFile.durationSeconds > (normal ?? session.caseFile.durationSeconds)
        stage = .result(Play(session: session, verdict: verdict, attemptID: attempt.id, relaxed: relaxed))
    }

    /// [Classer le dossier] / « Classer quand même »: the assignment (once, after #001), then the
    /// Bureau — where a solved case's card receives the RÉSOLU stamp.
    private func fileAway(_ play: Play, anyway: Bool) {
        if play.session.slot == .story {
            // T-SIG-2: back to the BEN.
            let file = play.session.caseFile
            let used = file.durationSeconds - Int(play.verdict.remainingSeconds)
            attempts = ProgressStore.attempts()
            refreshStory()
            story.caseFinished(file.id, solved: play.verdict.isCorrect, score: play.verdict.score,
                               found: play.verdict.foundCount, total: play.verdict.totalCount,
                               seconds: max(0, used), alibi: file.isAlibi)
            stage = .story
            return
        }
        if play.session.caseFile.isAlibi {
            deskMode = .alibi
            goHome()
            return
        }
        if anyway { filedAnyway = true }
        attempts = ProgressStore.attempts()
        deskMode = .investigations
        justFiled = play.verdict.isCorrect ? play.session.caseFile.id : nil
        if let firstCase, play.session.caseFile.id == firstCase.id,
           PlayerStore.assignmentDue(attempts: attempts, firstCaseID: firstCase.id, filedAnyway: filedAnyway) {
            stage = .assignment(solved: play.verdict.isCorrect)
        } else {
            goHome()
        }
    }

    /// [REPRENDRE L'ENQUÊTE] after a wrong conclusion: the same case, the timer full again, and the
    /// pieces already filed kept (with their links).
    private func retry(_ play: Play) {
        let original = cases.first { $0.id == play.session.caseFile.id } ?? play.session.caseFile
        guard let session = makeSession(original, challenge: play.session.game.challenge, slot: play.session.slot) else { return }
        let entries = play.session.game.notebook
        session.begin()
        session.restoreNotebook(entries, seen: play.session.game.seen)
        stage = .playing(session)
    }

    /// « Consulter la solution » after a wrong answer: the attempt becomes unranked.
    private func reveal(_ play: Play) {
        ProgressStore.markRevealed(play.attemptID)
        attempts = ProgressStore.attempts()
        var revealed = play
        revealed.revealed = true
        stage = .result(revealed)
    }
}

/// The case files could not be read (§6-13 « Erreur de chargement »): never a blank screen — an
/// error card with [Réessayer].
struct DamagedFileView: View {
    let detail: String
    var onRetry: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PostItNote(title: L10n.t("error.damaged"),
                       message: L10n.t("error.damagedBody"),
                       action: L10n.t("error.retry"),
                       actionID: "error.retry",
                       onAction: onRetry)
                .overlay(RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
                    .strokeBorder(Trace.Colors.critical, lineWidth: 1))
            #if DEBUG
            Text(detail)
                .font(Trace.Fonts.monoSmall)
                .foregroundStyle(Trace.Colors.text3)
                .frame(maxWidth: 340, alignment: .leading)
            #endif
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DeskBackdrop())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("error.damaged")
    }
}

/// Launch arguments used by the UI tests (Debug builds only; ignored in Release):
/// `-UITestReset YES` clears the saved attempts and the investigation in progress,
/// `-UITestDuration <seconds>` shortens every case,
/// `-UITestFirstLaunch skip|show`: `skip` = a returning, assigned player (Élise A, tutorial seen);
/// `show` = a brand-new player (00 Première impression, who investigates, tutorial bubbles). The
/// reset also clears the story's save and the Bureau's remembered mode, and makes the story's lines
/// appear at once.
@MainActor
enum UITestHooks {
    static func applyAtLaunch() {
        #if DEBUG
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "UITestReset") {
            ProgressStore.reset()
            SavedInvestigationStore.clear()
            StorySaveStore.clear()
            StoryPreferences.reset()
            // Lines appear at once in the tests (the typewriter is tested by its own timing).
            StoryPreferences.textSpeed = .instant
            defaults.removeObject(forKey: Preferences.relaxedTimeKey)
            defaults.removeObject(forKey: Preferences.reduceMotionKey)
            defaults.removeObject(forKey: Preferences.deskModeKey)
        }
        switch defaults.string(forKey: "UITestFirstLaunch") {
        case "skip":
            PlayerStore.identity = .default
            PlayerStore.isAssigned = true
            TutorialCoach.markSeen()
        case "show":
            PlayerStore.reset()
            TutorialCoach.replay()
        default:
            break
        }
        #endif
    }

    static func adjusted(_ file: CaseFile) -> CaseFile {
        #if DEBUG
        let seconds = UserDefaults.standard.integer(forKey: "UITestDuration")
        if seconds > 0 {
            var copy = file
            copy.durationSeconds = seconds
            return copy
        }
        #endif
        return file
    }
}

/// Phone while investigating; when the timer hits zero (or the player concludes), the conclusion.
struct PlayingView: View {
    let session: GameSession
    let onQuit: () -> Void

    var body: some View {
        if session.phase == .investigating {
            InvestigationView(session: session, onQuit: onQuit)
                .transition(.opacity)
        } else if session.caseFile.isAlibi {
            AlibiVerdictView(session: session)
                .transition(.opacity)
        } else {
            AccusationView(session: session)
                .transition(.opacity)
        }
    }
}
#endif
