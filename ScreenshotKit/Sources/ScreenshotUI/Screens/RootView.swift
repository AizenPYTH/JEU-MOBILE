#if os(iOS)
import SwiftUI
import CaseEngine
import CaseLibrary

/// Launch (01): the launch screen does the real start-up work, then fades into the game.
public struct RootView: View {
    @State private var loader = LaunchLoader()
    @State private var boot: BootData?

    public init() {}

    public var body: some View {
        ZStack {
            Trace.Colors.launch.ignoresSafeArea()
            if let boot {
                GameRoot(boot: boot)
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
}

/// The game's flow (final handoff §C, §E).
///
/// First launch: Titre (02) → Qui enquête ? (03) → Dossier #001 (04) → Téléphone. After #001:
/// Affectation (12) → Bureau (13). Later launches: Titre-reprise (02b) if an investigation is in
/// progress, the Bureau otherwise. In a case: Dossier → ouverture → Téléphone ⇄ Carnet → Conclusion
/// (09) → Vérification + Rapport (10–11) → Bureau.
struct GameRoot: View {
    enum Stage {
        /// 02 · first launch.
        case title
        /// 02b · an investigation is in progress.
        case titleResume
        /// 03 · who investigates (first launch).
        case whoInvestigates
        case home
        case cases
        case archive
        case profile
        case settings
        /// 04 · the case file, briefing first.
        case intro(CaseFile)
        /// From the case file to the phone: the sealed bag, the zoom, the lock screen.
        case opening(GameSession)
        case playing(GameSession)
        /// 10–11 · verification, then the closing report.
        case result(Play)
        /// 12 · official assignment to the BEN (once, after #001).
        case assignment(solved: Bool)
        case archived(CaseFile, Attempt)
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
    @State private var attempts: [Attempt] = []
    /// The investigation the player left, if any ("Reprendre l'enquête").
    @State private var savedGame: SavedInvestigation?
    @State private var identity: PlayerIdentity = PlayerStore.identity
    @State private var assigned: Bool = PlayerStore.isAssigned
    /// « Classer quand même » was chosen on a report of #001.
    @State private var filedAnyway = false
    @AppStorage(Preferences.reduceMotionKey) private var reduceMotion = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private let cases: [CaseFile]
    private let rules: GameRules?
    private let loadError: String?

    /// Everything was loaded by the launch screen (`LaunchLoader`): fonts, saves, rules, cases.
    init(boot: BootData) {
        _attempts = State(initialValue: boot.attempts)
        _savedGame = State(initialValue: boot.savedGame)
        cases = boot.cases
        rules = boot.rules
        loadError = boot.loadError
        let inProgress = boot.savedGame.map { saved in boot.cases.contains { $0.id == saved.snapshot.caseID } } ?? false
        let first: Stage
        if inProgress {
            first = .titleResume
        } else if !PlayerStore.isAssigned {
            first = .title
        } else {
            first = .home
        }
        _stage = State(initialValue: first)
    }

    private var noMotion: Bool { reduceMotion || systemReduceMotion }

    var body: some View {
        ZStack {
            Trace.Colors.desk.ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
        .animation(noMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper, value: stageKey)
    }

    /// Screens of the desk slide in (fade + 24 pt); with reduced motion, they only fade.
    private var push: AnyTransition {
        noMotion ? .opacity : .opacity.combined(with: .offset(x: 24))
    }

    @ViewBuilder
    private var content: some View {
        if let loadError {
            DamagedFileView(detail: loadError)
        } else {
            switch stage {
            case .title:
                TitleScreen(onStart: beginFirstCase, onSettings: { openSettings(from: .title) })
                    .transition(.opacity)
            case .titleResume:
                if let resumable {
                    TitleResumeScreen(caseFile: resumable.file,
                                      remainingSeconds: resumable.saved.remainingSeconds,
                                      pieces: resumable.saved.snapshot.notebook.count,
                                      onResume: resumeSaved,
                                      onDesk: goHome,
                                      onSettings: { openSettings(from: .titleResume) })
                        .environment(\.caseNumber, resumable.file.number)
                        .transition(.opacity)
                } else {
                    TitleScreen(onStart: beginFirstCase, onSettings: { openSettings(from: .title) })
                }
            case .whoInvestigates:
                WhoInvestigatesScreen(initial: identity, allowsAppearance: false,
                                      onContinue: { chosen in
                                          PlayerStore.identity = chosen
                                          identity = chosen
                                          openFirstCase()
                                      },
                                      onBack: { stage = .title })
                    .transition(push)
            case .home:
                BureauView(cases: cases, progress: progress, resumable: resumable, featured: resumable?.file ?? nextCase,
                           identity: identity, rank: rank, assigned: assigned,
                           onOpen: { stage = .intro($0) },
                           onResume: resumeSaved,
                           onProfile: { selectTab(.investigator) },
                           onTab: selectTab)
                    .transition(.opacity)
            case .cases, .archive:
                ArchivesView(cases: cases, progress: progress, attempts: attempts, savedCaseID: resumable?.file.id,
                             onOpen: { stage = .intro($0) }, onTab: selectTab)
                    .transition(.opacity)
            case .profile:
                InvestigatorView(attempts: attempts, cases: cases, identity: identity, assigned: assigned,
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
            case .result(let play):
                ResultView(verdict: play.verdict, caseFile: play.session.caseFile, names: names(play.session),
                           revealed: play.revealed,
                           relaxed: play.relaxed,
                           culprit: contact(play.session, play.verdict.culprit),
                           accused: contact(play.session, play.verdict.accused),
                           onFile: { fileAway(play, anyway: false) },
                           onRetry: { retry(play) },
                           onFileAnyway: { fileAway(play, anyway: true) },
                           onRevealRequested: { reveal(play) })
                    .id(play.revealed)
                    .environment(\.caseNumber, play.session.caseFile.number)
                    .transition(.opacity)
            case .assignment(let solved):
                AssignmentView(identity: identity, rank: rank, solved: solved,
                               remainingCases: max(0, cases.count - 1),
                               onDesk: {
                                   PlayerStore.isAssigned = true
                                   assigned = true
                                   goHome()
                               })
                    .transition(.opacity)
            case .archived(let file, let attempt):
                ArchivedCaseView(caseFile: file, attempt: attempt, onClose: { stage = .archive })
                    .environment(\.caseNumber, file.number)
                    .transition(push)
            }
        }
    }

    private var progress: [String: CaseProgress] { ProgressStore.summary(of: attempts) }

    /// Rank from the number of cases solved (ENQUÊTEUR → INSPECTEUR → SENIOR → EXPÉRIMENTÉ).
    private var rank: Rank { Rank.forSolved(progress.values.filter(\.solved).count) }

    private func selectTab(_ tab: DeskTab) {
        attempts = ProgressStore.attempts()
        savedGame = SavedInvestigationStore.load()
        switch tab {
        case .bureau: stage = .home
        case .archives: stage = .cases
        case .investigator: stage = .profile
        }
    }

    private func openSettings(from origin: Stage) {
        settingsReturn = origin
        stage = .settings
    }

    /// The first case not solved yet (or the last one).
    private var nextCase: CaseFile? {
        cases.first { progress[$0.id]?.solved != true } ?? cases.last
    }

    private var firstCase: CaseFile? { cases.first { $0.number == 1 } ?? cases.first }

    private var stageKey: String {
        switch stage {
        case .title: "title"
        case .titleResume: "titleResume"
        case .whoInvestigates: "who"
        case .home: "home"
        case .cases: "cases"
        case .archive: "archive"
        case .profile: "profile"
        case .settings: "settings"
        case .intro(let f): "intro-\(f.id)"
        case .opening: "opening"
        case .playing: "playing"
        case .result(let p): "result-\(p.revealed)"
        case .assignment: "assignment"
        case .archived(_, let a): "archived-\(a.id)"
        }
    }

    /// 02 → 03 (if nobody chose yet) → 04 Dossier #001.
    private func beginFirstCase() {
        if PlayerStore.hasChosen { openFirstCase() } else { stage = .whoInvestigates }
    }

    private func openFirstCase() {
        if let firstCase { stage = .intro(firstCase) } else { stage = .home }
    }

    /// Back from a case file that was not started: the title screen before the assignment, the
    /// Bureau after.
    private func leaveBriefing() {
        if assigned { goHome() } else { goToStart() }
    }

    private func goToStart() {
        attempts = ProgressStore.attempts()
        savedGame = SavedInvestigationStore.load()
        stage = resumable != nil ? .titleResume : (assigned ? .home : .title)
    }

    private func goHome() {
        attempts = ProgressStore.attempts()
        savedGame = SavedInvestigationStore.load()
        stage = .home
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
            goToStart()
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

    /// A new investigation at a challenge level (replaces any saved one).
    private func start(_ original: CaseFile, challenge: Challenge) {
        guard let session = makeSession(original, challenge: challenge) else { return }
        SavedInvestigationStore.clear()
        savedGame = nil
        // The clock starts when the phone is in the player's hands.
        stage = .opening(session)
    }

    private func makeSession(_ original: CaseFile, challenge: Challenge) -> GameSession? {
        guard let rules else { return nil }
        var played = original.configured(for: challenge, rules: rules)
        played.durationSeconds = Self.relaxed(played.durationSeconds)
        played = UITestHooks.adjusted(played)
        return GameSession(caseFile: played, rules: rules, challenge: challenge) { finished($0) }
    }

    /// End of the opening: the phone just unlocked is the one the player now holds.
    private func handOver(_ session: GameSession) {
        session.begin()
        stage = .playing(session)
    }

    /// Leaving the phone (« Mettre en pause »): the investigation is saved. Back to the Bureau (which
    /// offers to resume it); before the assignment, to the title screen's resume card.
    private func quit(_ session: GameSession) {
        session.pause()
        if assigned { goHome() } else { goToStart() }
    }

    private func finished(_ verdict: Verdict) {
        guard case .playing(let session) = stage else { return }
        let attempt = Attempt(caseID: session.caseFile.id, date: .now, score: verdict.score, solved: verdict.isCorrect,
                              ranked: true, found: verdict.foundCount, total: verdict.totalCount,
                              hintsUsed: verdict.hintsUsed, challenge: session.game.challenge,
                              timeUsed: session.caseFile.durationSeconds - verdict.remainingSeconds)
        ProgressStore.record(attempt)
        attempts = ProgressStore.attempts()
        savedGame = nil
        stage = .result(Play(session: session, verdict: verdict, attemptID: attempt.id, relaxed: Preferences.relaxedTime))
    }

    /// [CLASSER LE DOSSIER] / « Classer quand même »: the assignment (once, after #001), then the Bureau.
    private func fileAway(_ play: Play, anyway: Bool) {
        if anyway { filedAnyway = true }
        attempts = ProgressStore.attempts()
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
        guard let session = makeSession(original, challenge: play.session.game.challenge) else { return }
        let entries = play.session.game.notebook
        session.begin()
        session.restoreNotebook(entries)
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

/// The case files could not be read (never a blank screen): a post-it on the desk.
struct DamagedFileView: View {
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("error.damaged")).fieldLabel(Trace.Colors.stamp)
            Text(L10n.t("error.damagedBody")).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            #if DEBUG
            Text(detail).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
            #endif
        }
        .padding(20)
        .frame(maxWidth: 320, alignment: .leading)
        .paper(Trace.Colors.noteYellow, lifted: true)
        .rotationEffect(.degrees(-1.5))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TraceDesk())
    }
}

/// Launch arguments used by the UI tests (Debug builds only; ignored in Release):
/// `-UITestReset YES` clears the saved attempts and the investigation in progress,
/// `-UITestDuration <seconds>` shortens every case,
/// `-UITestFirstLaunch skip|show`: `skip` = a returning, assigned player (Élise A, tutorial seen);
/// `show` = a brand-new player (title, who investigates, tutorial bubbles).
enum UITestHooks {
    static func applyAtLaunch() {
        #if DEBUG
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "UITestReset") {
            ProgressStore.reset()
            SavedInvestigationStore.clear()
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
        } else {
            AccusationView(session: session)
                .transition(.opacity)
        }
    }
}
#endif
