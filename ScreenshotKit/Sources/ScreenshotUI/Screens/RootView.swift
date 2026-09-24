#if os(iOS)
import SwiftUI
import CaseEngine
import CaseLibrary

/// Home → Affaires → Intro → investigation (phone) → time up / accusation → result → score.
public struct RootView: View {
    enum Stage {
        case onboarding
        case home
        case cases
        case archive
        case profile
        case settings
        case intro(CaseFile)
        case cinematic(GameSession, IntroScene)
        case playing(GameSession)
        case result(Play)
        case score(Play)
        case archived(CaseFile, Attempt)
    }

    /// A finished investigation on its way through the result screens.
    struct Play {
        let session: GameSession
        let verdict: Verdict
        let attemptID: UUID
        var revealed = false
    }

    @State private var stage: Stage = .home
    @State private var attempts: [Attempt] = []
    /// The investigation the player left, if any ("Reprendre l'enquête").
    @State private var savedGame: SavedInvestigation?
    @AppStorage(Preferences.reduceMotionKey) private var reduceMotion = false
    private let cases: [CaseFile]
    private let rules: GameRules?
    private let loadError: String?

    public init() {
        AppFonts.register()
        UITestHooks.applyAtLaunch()
        _attempts = State(initialValue: ProgressStore.attempts())
        _savedGame = State(initialValue: SavedInvestigationStore.load())
        _stage = State(initialValue: UITestHooks.showsOnboarding(default: !Preferences.onboardingDone) ? .onboarding : .home)
        // Load into locals first: each stored `let` must be initialised exactly once, and a failure
        // in the second load must not re-assign what the first one already set.
        let loaded: (cases: [CaseFile], rules: GameRules?, error: String?)
        do {
            let cases = try CaseLibrary.loadCases().sorted { $0.number < $1.number }
            let rules = try CaseLibrary.loadRules()
            loaded = (cases, rules, nil)
        } catch {
            loaded = ([], nil, String(describing: error))
        }
        cases = loaded.cases
        rules = loaded.rules
        loadError = loaded.error
    }

    public var body: some View {
        ZStack {
            Theme.Colors.ink0.ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : Theme.Motion.emphasized(), value: stageKey)
        .transaction { if reduceMotion { $0.animation = nil } }
    }

    @ViewBuilder
    private var content: some View {
        if let loadError {
            VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                Text(L10n.t("error.damaged")).overline(Theme.Colors.alertText)
                Text(loadError).font(Theme.Fonts.data).foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.marginGame)
        } else {
            switch stage {
            case .home:
                HomeView(next: nextCase, resumable: resumable, progress: progress, attemptsCount: attempts.count,
                         onStart: { stage = .intro($0) },
                         onResume: resumeSaved,
                         onNavigate: { stage = $0 })
                    .transition(.opacity)
            case .cases:
                CasesView(cases: cases, progress: progress, onOpen: { stage = .intro($0) }, onBack: goHome)
                    .transition(.move(edge: .trailing))
            case .archive:
                ArchiveView(cases: cases, attempts: attempts, progress: progress,
                            onOpen: { file, attempt in stage = .archived(file, attempt) }, onBack: goHome)
                    .transition(.move(edge: .trailing))
            case .profile:
                ProfileView(attempts: attempts, caseCount: cases.count, onBack: goHome)
                    .transition(.move(edge: .trailing))
            case .settings:
                GameSettingsView(onBack: goHome, onReplayOnboarding: { stage = .onboarding })
                    .transition(.move(edge: .trailing))
            case .onboarding:
                OnboardingView {
                    Preferences.onboardingDone = true
                    goHome()
                }
                    .transition(.move(edge: .trailing))
            case .intro(let file):
                CaseIntroView(caseFile: file,
                              durations: durations(of: file),
                              unlocked: Set(Challenge.allCases.filter { level in
                                  rules?.isUnlocked(level, solvedAt: solvedLevels(of: file)) ?? true
                              }),
                              levels: ProgressStore.levels(of: file.id, in: attempts),
                              saved: resumable?.file.id == file.id ? resumable?.saved : nil,
                              onStart: { start(file, challenge: $0) },
                              onResume: resumeSaved,
                              onClose: goHome)
                    .transition(.opacity)
            case .cinematic(let session, let scene):
                CinematicView(scene: scene, caseFile: session.caseFile, session: session, onFinish: { handOver(session) })
                    .transition(.opacity)
            case .playing(let session):
                PlayingView(session: session, onQuit: { quit(session) })
                    .transition(.opacity)
            case .result(let play):
                ResultView(verdict: play.verdict, caseFile: play.session.caseFile, names: names(play.session),
                           onScore: { stage = .score(play) },
                           onReplay: { replay(play) },
                           onRevealRequested: { reveal(play) },
                           revealed: play.revealed,
                           accusedEvidence: accusedEvidence(play.session, play.verdict.accused),
                           culprit: culprit(play.session, play.verdict.culprit),
                           accused: culprit(play.session, play.verdict.accused))
                    .id(play.revealed)
                    .transition(.opacity)
            case .score(let play):
                ScoreView(verdict: play.verdict, duration: play.session.caseFile.durationSeconds,
                          caseTitle: play.session.caseFile.title,
                          onReplay: { replay(play) },
                          onNext: { stage = nextCase(after: play.session.caseFile).map { .intro($0) } ?? .cases })
                    .transition(.opacity)
            case .archived(let file, let attempt):
                ArchivedCaseView(caseFile: file, attempt: attempt, onClose: { stage = .archive })
                    .transition(.move(edge: .trailing))
            }
        }
    }

    private var progress: [String: CaseProgress] { ProgressStore.summary(of: attempts) }

    /// The first case not solved yet (or the last one).
    private var nextCase: CaseFile? {
        cases.first { progress[$0.id]?.solved != true } ?? cases.last
    }

    private func nextCase(after file: CaseFile) -> CaseFile? {
        cases.first { $0.number > file.number }
    }

    private var stageKey: String {
        switch stage {
        case .onboarding: "onboarding"
        case .home: "home"
        case .cases: "cases"
        case .archive: "archive"
        case .profile: "profile"
        case .settings: "settings"
        case .intro(let f): "intro-\(f.id)"
        case .cinematic: "cinematic"
        case .playing: "playing"
        case .result(let p): "result-\(p.revealed)"
        case .score: "score"
        case .archived(_, let a): "archived-\(a.id)"
        }
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

    /// "Reprendre l'enquête": back to the same screen, same time, same notebook.
    private func resumeSaved() {
        guard let rules, let resumable,
              let session = GameSession(restoring: resumable.saved, caseFile: resumable.file, rules: rules,
                                        onFinish: { finished($0) }) else {
            SavedInvestigationStore.clear()
            savedGame = nil
            return
        }
        session.begin()
        stage = .playing(session)
    }

    private func names(_ session: GameSession) -> [SuspectID: String] {
        Dictionary(uniqueKeysWithValues: session.caseFile.suspects.map { ($0.id, session.game.name(of: $0.contact)) })
    }

    /// What the accusation rested on: the notebook items the player linked to the accused.
    private func accusedEvidence(_ session: GameSession, _ accused: SuspectID) -> [String] {
        session.game.linkedEntries(for: accused).map { ItemDescriber.describe($0.ref, in: session.game).label }
    }

    /// The contact behind a suspect (the culprit, or whoever was accused).
    private func culprit(_ session: GameSession, _ id: SuspectID) -> Contact? {
        session.game.index.suspect(id).flatMap { session.game.contact($0.contact) }
    }

    /// Duration of a case at each level.
    private func durations(of file: CaseFile) -> [Challenge: Int] {
        var result: [Challenge: Int] = [:]
        for level in Challenge.allCases {
            result[level] = rules.map { file.duration(for: level, rules: $0) } ?? file.durationSeconds
        }
        return result
    }

    /// Levels at which a case was already solved (ranked or not).
    private func solvedLevels(of file: CaseFile) -> Set<Challenge> {
        Set(attempts.filter { $0.caseID == file.id && $0.solved }.map(\.level))
    }

    /// A new investigation at a challenge level (replaces any saved one).
    private func start(_ original: CaseFile, challenge: Challenge) {
        guard let rules else { return }
        SavedInvestigationStore.clear()
        savedGame = nil
        let played = UITestHooks.adjusted(original.configured(for: challenge, rules: rules))
        let session = GameSession(caseFile: played, rules: rules, challenge: challenge) { finished($0) }
        if let scene = played.introScene, UITestHooks.playsCinematic {
            // The clock starts when the phone is in the player's hands, not during the opening.
            stage = .cinematic(session, scene)
        } else {
            session.begin()
            stage = .playing(session)
        }
    }

    /// End of the opening: the phone just picked up is the one the player now holds.
    private func handOver(_ session: GameSession) {
        session.begin()
        stage = .playing(session)
    }

    /// "Rejouer": the same case, from the start, at the same level.
    private func replay(_ play: Play) {
        let original = cases.first { $0.id == play.session.caseFile.id } ?? play.session.caseFile
        start(original, challenge: play.session.game.challenge)
    }

    /// "Quitter l'enquête": the investigation is saved (it paused when the question was asked).
    private func quit(_ session: GameSession) {
        session.pause()
        goHome()
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
        stage = .result(Play(session: session, verdict: verdict, attemptID: attempt.id))
    }

    /// "Révéler la solution" after a wrong answer: the attempt becomes unranked.
    private func reveal(_ play: Play) {
        ProgressStore.markRevealed(play.attemptID)
        attempts = ProgressStore.attempts()
        var revealed = play
        revealed.revealed = true
        stage = .result(revealed)
    }
}

/// Launch arguments used by the UI tests (Debug builds only; ignored in Release):
/// `-UITestReset YES` clears the saved attempts, `-UITestDuration <seconds>` shortens every case,
/// `-UITestOnboarding show|skip` forces the first-launch onboarding on or off,
/// `-UITestCinematic skip` starts cases without their opening sequence.
enum UITestHooks {
    static var playsCinematic: Bool {
        #if DEBUG
        if UserDefaults.standard.string(forKey: "UITestCinematic") == "skip" { return false }
        #endif
        return true
    }

    static func showsOnboarding(default value: Bool) -> Bool {
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "UITestOnboarding") {
        case "show": return true
        case "skip": return false
        default: break
        }
        #endif
        return value
    }

    static func applyAtLaunch() {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "UITestReset") {
            ProgressStore.reset()
            SavedInvestigationStore.clear()
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

/// Phone while investigating; "temps écoulé" when the timer hits zero; then the accusation.
struct PlayingView: View {
    let session: GameSession
    let onQuit: () -> Void
    @State private var timeUpShown = false

    var body: some View {
        if session.phase == .investigating {
            InvestigationView(session: session, onQuit: onQuit)
                .transition(.opacity)
        } else if session.remainingSeconds <= 0 && !timeUpShown {
            TimeUpView { timeUpShown = true }
                .transition(.opacity)
        } else {
            AccusationView(session: session)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
#endif
